#!/bin/bash

# Validation script to test the n8n production setup
# This script checks if all components are working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info "N8N Production Environment Validation"
print_info "======================================"

# Check if setup.json exists
if [ -f "$SCRIPT_DIR/setup.json" ]; then
    print_status "Configuration file found"
    DOMAIN=$(jq -r '.domain' "$SCRIPT_DIR/setup.json" 2>/dev/null || echo "")
else
    print_error "setup.json not found"
    exit 1
fi

# Check if .env exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    print_status "Environment file exists"
else
    print_error ".env file not found"
    exit 1
fi

# Check Docker containers
print_info "Checking Docker containers..."
cd "$SCRIPT_DIR"

if docker-compose ps | grep -q "Up"; then
    print_status "Docker containers are running"
    
    # Check PostgreSQL health
    if docker-compose ps postgres | grep -q "healthy"; then
        print_status "PostgreSQL is healthy"
    else
        print_warning "PostgreSQL may not be healthy"
    fi
    
    # Check n8n health
    if docker-compose ps n8n | grep -q "Up"; then
        print_status "n8n container is running"
    else
        print_error "n8n container is not running"
    fi
else
    print_error "Docker containers are not running"
    print_info "Try: docker-compose up -d"
fi

# Check Apache
print_info "Checking Apache..."
if systemctl is-active --quiet apache2; then
    print_status "Apache is running"
    
    if apache2ctl configtest &>/dev/null; then
        print_status "Apache configuration is valid"
    else
        print_warning "Apache configuration has issues"
    fi
else
    print_error "Apache is not running"
fi

# Check n8n accessibility
print_info "Checking n8n accessibility..."
if curl -s -I http://127.0.0.1:5678 | grep -q "200 OK"; then
    print_status "n8n is responding locally"
else
    print_warning "n8n is not responding on local port 5678"
fi

# Check SSL certificate if domain is configured
if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "your-domain.com" ]; then
    print_info "Checking SSL certificate for $DOMAIN..."
    
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        print_status "SSL certificate exists"
        
        # Check certificate expiry
        if openssl x509 -checkend 2592000 -noout -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" &>/dev/null; then
            print_status "SSL certificate is valid for at least 30 days"
        else
            print_warning "SSL certificate expires within 30 days"
        fi
    else
        print_warning "SSL certificate not found"
    fi
    
    # Check if domain resolves
    if curl -s -I "https://$DOMAIN" | grep -q "200 OK"; then
        print_status "Domain is accessible via HTTPS"
    else
        print_warning "Domain is not accessible via HTTPS (DNS/firewall issue?)"
    fi
else
    print_info "Domain not configured, skipping SSL checks"
fi

# Check backup script
if [ -f "$SCRIPT_DIR/backup-db.sh" ] && [ -x "$SCRIPT_DIR/backup-db.sh" ]; then
    print_status "Backup script is ready"
else
    print_warning "Backup script not found or not executable"
fi

# Check cron job
if crontab -l 2>/dev/null | grep -q certbot; then
    print_status "Certificate auto-renewal is configured"
else
    print_warning "Certificate auto-renewal cron job not found"
fi

print_info ""
print_info "Validation completed!"

if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "your-domain.com" ]; then
    print_info "Your n8n instance should be available at: https://$DOMAIN"
else
    print_info "Configure your domain in setup.json and run setup-production.sh"
fi
