#!/bin/bash

# N8N Production Environment Setup Script
# This script sets up n8n with PostgreSQL, SSL certificates, and Apache reverse proxy
# using configuration from setup.json

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root (use sudo)"
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if setup.json exists
if [ ! -f "$SCRIPT_DIR/setup.json" ]; then
    print_error "setup.json file not found!"
    print_status "Please copy setup.json.template to setup.json and configure it with your values."
    print_status "Example:"
    print_status "  cp setup.json.template setup.json"
    print_status "  nano setup.json"
    exit 1
fi

# Check if jq is installed for JSON parsing
if ! command -v jq &> /dev/null; then
    print_status "Installing jq for JSON parsing..."
    apt update && apt install -y jq
fi

# Parse configuration from setup.json
print_status "Reading configuration from setup.json..."

DOMAIN=$(jq -r '.domain' "$SCRIPT_DIR/setup.json")
EMAIL=$(jq -r '.email' "$SCRIPT_DIR/setup.json")
POSTGRES_PASSWORD=$(jq -r '.postgres_password' "$SCRIPT_DIR/setup.json")
N8N_BASIC_AUTH_USER=$(jq -r '.n8n_basic_auth_user' "$SCRIPT_DIR/setup.json")
N8N_BASIC_AUTH_PASSWORD=$(jq -r '.n8n_basic_auth_password' "$SCRIPT_DIR/setup.json")
TIMEZONE=$(jq -r '.timezone' "$SCRIPT_DIR/setup.json")
PROJECT_NAME=$(jq -r '.project_name' "$SCRIPT_DIR/setup.json")

# Validate required fields
if [ "$DOMAIN" = "null" ] || [ "$DOMAIN" = "your-domain.com" ]; then
    print_error "Please configure the domain in setup.json"
    exit 1
fi

if [ "$EMAIL" = "null" ] || [ "$EMAIL" = "admin@your-domain.com" ]; then
    print_error "Please configure the email in setup.json"
    exit 1
fi

if [ "$POSTGRES_PASSWORD" = "null" ] || [ "$POSTGRES_PASSWORD" = "your_secure_postgres_password_here" ]; then
    print_error "Please configure a secure postgres_password in setup.json"
    exit 1
fi

if [ "$N8N_BASIC_AUTH_PASSWORD" = "null" ] || [ "$N8N_BASIC_AUTH_PASSWORD" = "your_secure_n8n_password_here" ]; then
    print_error "Please configure a secure n8n_basic_auth_password in setup.json"
    exit 1
fi

print_status "Configuration loaded:"
print_status "  Domain: $DOMAIN"
print_status "  Email: $EMAIL"
print_status "  Project: $PROJECT_NAME"
print_status "  Timezone: $TIMEZONE"

echo
print_status "Starting n8n production environment setup..."

# Install required packages
print_status "Installing required packages..."
apt update
apt install -y apache2 certbot python3-certbot-apache docker.io docker-compose jq

# Enable required Apache modules
print_status "Enabling Apache modules..."
a2enmod ssl rewrite proxy proxy_http proxy_wstunnel headers

# Create environment file from template
print_status "Creating .env file from template..."
if [ -f "$SCRIPT_DIR/.env.template" ]; then
    sed -e "s/{{POSTGRES_PASSWORD}}/$POSTGRES_PASSWORD/g" \
        -e "s/{{N8N_BASIC_AUTH_USER}}/$N8N_BASIC_AUTH_USER/g" \
        -e "s/{{N8N_BASIC_AUTH_PASSWORD}}/$N8N_BASIC_AUTH_PASSWORD/g" \
        -e "s/{{TIMEZONE}}/$TIMEZONE/g" \
        -e "s/{{DOMAIN_NAME}}/$DOMAIN/g" \
        "$SCRIPT_DIR/.env.template" > "$SCRIPT_DIR/.env"
    
    # Add DOMAIN_NAME to .env file if not already present in template
    if ! grep -q "DOMAIN_NAME=" "$SCRIPT_DIR/.env"; then
        echo "DOMAIN_NAME=$DOMAIN" >> "$SCRIPT_DIR/.env"
    fi
    
    print_status ".env file created successfully"
else
    print_error ".env.template not found!"
    exit 1
fi

# Create Apache virtual host configuration
print_status "Creating Apache virtual host configuration..."
VHOST_FILE="/etc/apache2/sites-available/${DOMAIN}.conf"

if [ -f "$SCRIPT_DIR/vhost.conf.template" ]; then
    sed "s/{{DOMAIN}}/$DOMAIN/g" "$SCRIPT_DIR/vhost.conf.template" > "$VHOST_FILE"
    print_status "Virtual host configuration created: $VHOST_FILE"
else
    print_error "vhost.conf.template not found!"
    exit 1
fi

# Enable the site
print_status "Enabling Apache site..."
a2ensite "$DOMAIN"

# Test Apache configuration
print_status "Testing Apache configuration..."
if apache2ctl configtest; then
    print_status "Apache configuration is valid"
else
    print_error "Apache configuration test failed"
    exit 1
fi

# Start Apache
print_status "Starting Apache..."
systemctl enable apache2
systemctl start apache2

# Start Docker containers
print_status "Starting Docker containers..."
cd "$SCRIPT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found in $SCRIPT_DIR"
    exit 1
fi

# Start the containers
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 30

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_status "Docker services are running successfully!"
else
    print_error "Docker services failed to start. Check logs with: docker-compose logs"
    exit 1
fi

# Generate SSL certificate
print_status "Generating SSL certificate for $DOMAIN..."
if certbot --apache -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive; then
    print_status "SSL certificate generated successfully!"
else
    print_error "Failed to generate SSL certificate"
    print_warning "You may need to ensure DNS is pointing to this server"
    print_warning "You can try running certbot manually later:"
    print_warning "sudo certbot --apache -d $DOMAIN --email $EMAIL --agree-tos"
fi

# Set up automatic certificate renewal
print_status "Setting up automatic certificate renewal..."
(crontab -l 2>/dev/null | grep -v certbot; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Create backup script with domain-specific naming
print_status "Creating backup script..."
BACKUP_SCRIPT="$SCRIPT_DIR/backup-db.sh"
sed "s/{{DOMAIN}}/$DOMAIN/g" << 'EOF' > "$BACKUP_SCRIPT"
#!/bin/bash

# Backup script for n8n PostgreSQL database
# This script creates a backup of the n8n database

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backup"
CONTAINER_NAME="$(basename $SCRIPT_DIR)_postgres_1"
DB_NAME="n8n"
DB_USER="n8n"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="n8n_backup_${TIMESTAMP}.sql"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Creating backup of n8n database..."

# Create database backup
docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" > "${BACKUP_DIR}/${BACKUP_FILE}"

# Compress the backup
gzip "${BACKUP_DIR}/${BACKUP_FILE}"

echo "Backup created: ${BACKUP_DIR}/${BACKUP_FILE}.gz"

# Keep only the last 7 days of backups
find "$BACKUP_DIR" -name "n8n_backup_*.sql.gz" -mtime +7 -delete

echo "Backup completed successfully!"
EOF

chmod +x "$BACKUP_SCRIPT"

# Create restore script
print_status "Creating restore script..."
RESTORE_SCRIPT="$SCRIPT_DIR/restore-db.sh"
cat << 'EOF' > "$RESTORE_SCRIPT"
#!/bin/bash

# Restore script for n8n PostgreSQL database
# Usage: ./restore-db.sh <backup_file.sql.gz>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    echo "Available backups:"
    ls -la "$SCRIPT_DIR/backup/n8n_backup_"*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"
CONTAINER_NAME="$(basename $SCRIPT_DIR)_postgres_1"
DB_NAME="n8n"
DB_USER="n8n"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found!"
    exit 1
fi

echo "Restoring n8n database from: $BACKUP_FILE"

# Stop n8n service to prevent conflicts
echo "Stopping n8n service..."
cd "$SCRIPT_DIR"
docker-compose stop n8n

# Restore database
echo "Restoring database..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    # If file is compressed
    gunzip -c "$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"
else
    # If file is not compressed
    docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$BACKUP_FILE"
fi

# Start n8n service
echo "Starting n8n service..."
docker-compose start n8n

echo "Database restore completed successfully!"
EOF

chmod +x "$RESTORE_SCRIPT"

print_status "Setup completed successfully!"
echo
print_status "================================================"
print_status "🎉 N8N Production Environment Ready!"
print_status "================================================"
echo
print_status "Your n8n instance should now be available at: https://$DOMAIN"
echo
print_status "Login credentials:"
print_status "  Username: $N8N_BASIC_AUTH_USER"
print_status "  Password: $N8N_BASIC_AUTH_PASSWORD"
echo
print_status "Management commands (run from $SCRIPT_DIR):"
print_status "  Start services:     docker-compose up -d"
print_status "  Stop services:      docker-compose down"
print_status "  View logs:          docker-compose logs"
print_status "  View status:        docker-compose ps"
print_status "  Backup database:    ./backup-db.sh"
print_status "  Restore database:   ./restore-db.sh <backup_file>"
echo
print_status "SSL Certificate:"
print_status "  Domain: $DOMAIN"
print_status "  Auto-renewal: Enabled (daily at 12:00 PM)"
echo
print_status "🔒 Your n8n instance is secured with SSL and ready for production use!"
