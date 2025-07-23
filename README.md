# N8N Production Environment with Docker & SSL

**Created by Gilson Rincón, CEO and Co-founder of Solutto Consulting LLC**  
**Solutto Consulting LLC - https://www.soluttoconsulting.com**

*Licensed under the MIT License. See [LICENSE](LICENSE) file for complete terms and conditions.*

---

A production-ready n8n setup with PostgreSQL, Apache reverse proxy, and automatic SSL certificates using Let's Encrypt.

## Features

- **Production n8n**: Latest n8n with proper configuration
- **PostgreSQL Database**: Persistent data storage with health checks
- **SSL/TLS Encryption**: Automatic certificate generation and renewal
- **Apache Reverse Proxy**: With security headers and WebSocket support
- **Database Backups**: Automated backup and restore scripts
- **Template-based Setup**: Easy configuration with JSON templates

## 📋 About This Project

This n8n production deployment tool is developed by **Gilson Rincón**, CEO and Co-founder of **Solutto Consulting LLC**. We specialize in business automation, ERP implementations, and cloud infrastructure solutions.

### 🏢 Solutto Consulting LLC

We help businesses streamline their operations through automation and modern technology solutions. Our expertise includes:

- **Business Process Automation**: n8n, Zapier, and custom workflow solutions
- **ERP Implementation**: Odoo deployment and customization
- **Cloud Infrastructure**: Docker, Kubernetes, and cloud platform management
- **DevOps Solutions**: CI/CD pipelines and infrastructure automation

**Visit us at**: [https://www.soluttoconsulting.com](https://www.soluttoconsulting.com)

### 🚀 Recommended Hosting for Your n8n Instance

For reliable and cost-effective hosting of your n8n production environment, we recommend **Hetzner Cloud**:

**[🔗 Get Hetzner Cloud with €20 Credit (Affiliate Link)](https://hetzner.cloud/?ref=wXmhFZiVG5Ev)**

**Why Hetzner Cloud?**
- **Excellent Performance**: High-performance SSD storage and fast network
- **Competitive Pricing**: Best price-to-performance ratio in the market
- **European Infrastructure**: GDPR-compliant with data centers in Germany and Finland
- **Simple Setup**: Perfect for Docker-based deployments like this n8n setup
- **24/7 Support**: Professional support when you need it

*Recommended specs for n8n production:*
- **CPX21**: 3 vCPUs, 4GB RAM, 80GB SSD (~€4.51/month)
- **CPX31**: 4 vCPUs, 8GB RAM, 160GB SSD (~€8.21/month)

### ⚠️ Important Disclaimers

- **No Warranty**: This software is provided "AS IS" without warranty of any kind
- **User Responsibility**: You are responsible for testing and validating the setup before production use
- **Security**: Always follow security best practices and keep your systems updated
- **Backup**: Regular backups are essential - test your restore procedures regularly

---

## Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone git@github.com:Solutto-Consulting/n8n-deployment-tool.git
cd n8n-deployment-tool

# Copy and configure the setup file
cp setup.json.template setup.json
nano setup.json
```

> 💡 **Hosting Recommendation**: Need a server? Get [Hetzner Cloud with €20 free credit](https://hetzner.cloud/?ref=wXmhFZiVG5Ev) - perfect for n8n deployments!

### 2. Configure setup.json

Edit `setup.json` with your specific values:

```json
{
  "domain": "automations.yourdomain.com",
  "email": "admin@yourdomain.com", 
  "postgres_password": "your_very_secure_postgres_password",
  "n8n_basic_auth_user": "admin",
  "n8n_basic_auth_password": "your_very_secure_n8n_password",
  "timezone": "UTC",
  "project_name": "n8n-automation"
}
```

**Important**: 
- Replace all placeholder values with your actual configuration
- Use strong passwords for security
- Ensure your domain points to this server before running setup

### 3. Run Setup

```bash
# Make setup script executable
chmod +x setup-production.sh

# Run the setup (requires sudo)
sudo ./setup-production.sh
```

The script will:
- Install required packages (Apache, Docker, Certbot)
- Create Docker network (`solutto-internal`) if it doesn't exist
- Generate configuration files from templates
- Set up Apache virtual hosts
- Start Docker containers
- Generate SSL certificates
- Configure automatic certificate renewal

### 4. Access Your Instance

After setup completes, access your n8n instance at:
`https://your-domain.com`

Login with the credentials from your `setup.json` file.

## Project Structure

```
├── setup.json.template          # Configuration template
├── setup-production.sh          # Main setup script
├── docker-compose.yml.template  # Docker services configuration template
├── .env.template                # Environment variables template
├── vhost.conf.template          # Apache HTTP virtual host template
├── vhost-ssl.conf.template      # Apache HTTPS virtual host template
├── backup-db.sh.template        # Database backup script template
├── restore-db.sh.template       # Database restore script template
├── test-templates.sh            # Template validation script
├── validate-setup.sh            # Setup validation script
├── .gitignore                   # Git ignore rules
└── README.md                    # This file
```

## Generated Files (Not in Git)

After running setup, these files will be created:
- `setup.json` - Your configuration
- `docker-compose.yml` - Generated from template
- `.env` - Environment variables generated from template
- `backup-db.sh` - Database backup script
- `restore-db.sh` - Database restore script

## Management Commands

### Docker Services
```bash
# Start services
docker-compose up -d

# Stop services  
docker-compose down

# View logs
docker-compose logs

# View service status
docker-compose ps

# Update containers
docker-compose pull && docker-compose up -d
```

### Database Management
```bash
# Create backup
./backup-db.sh

# Restore from backup
./restore-db.sh backup/n8n_backup_20250714_120000.sql.gz

# Access PostgreSQL directly
docker-compose exec postgres psql -U n8n -d n8n
```

### SSL Certificate Management
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates manually
sudo certbot renew

# Test renewal process
sudo certbot renew --dry-run
```

## Configuration Reference

### setup.json Options

| Field | Description | Example |
|-------|-------------|---------|
| `domain` | Your n8n domain | `automations.yourdomain.com` |
| `email` | Admin email for SSL certificates | `admin@yourdomain.com` |
| `postgres_password` | PostgreSQL database password | Strong random password |
| `n8n_basic_auth_user` | n8n admin username | `admin` |
| `n8n_basic_auth_password` | n8n admin password | Strong random password |
| `timezone` | System timezone | `UTC`, `America/New_York`, etc. |
| `project_name` | Project identifier | `n8n-automation` |

### Environment Variables

The following environment variables are automatically configured:

- **Database**: `DB_TYPE`, `DB_POSTGRESDB_*`
- **n8n Settings**: `N8N_HOST`, `N8N_PROTOCOL`, `WEBHOOK_URL`
- **Security**: `N8N_BASIC_AUTH_*`, `N8N_SECURE_COOKIE`
- **Performance**: `EXECUTIONS_DATA_PRUNE`, `N8N_METRICS`

## Security Features

### Implemented Security
- ✅ SSL/TLS encryption with Let's Encrypt
- ✅ HTTP to HTTPS redirect
- ✅ Security headers (HSTS, XSS protection, etc.)
- ✅ Basic authentication for n8n
- ✅ Database password protection
- ✅ Container network isolation

### Recommended Additional Security
- Configure firewall (UFW/iptables)
- Regular security updates
- Monitor logs for suspicious activity
- Use strong, unique passwords
- Consider IP whitelisting for admin access

## Backup Strategy

### Automatic Backups
- Database backups retain 7 days
- SSL certificates auto-renew every 90 days
- Cron job runs daily at 12:00 PM

### Manual Backup
```bash
# Create immediate backup
./backup-db.sh

# Schedule additional backups
sudo crontab -e
# Add: 0 2 * * * /path/to/your/project/backup-db.sh
```

## Troubleshooting

### Common Issues

**SSL Certificate Generation Fails**
- Ensure domain DNS points to your server
- Check if ports 80/443 are accessible
- Verify Apache is running: `sudo systemctl status apache2`

**n8n Not Accessible**
- Check container status: `docker-compose ps`
- View logs: `docker-compose logs n8n`
- Verify Apache proxy: `sudo apache2ctl configtest`

**Database Connection Issues**
- Check PostgreSQL container: `docker-compose logs postgres`
- Verify environment variables in `.env`
- Ensure database is healthy: `docker-compose ps`

**Docker Network Issues**
- Verify the `solutto-internal` network exists: `docker network ls`
- If missing, create it manually: `docker network create solutto-internal`
- Check network connectivity between containers: `docker network inspect solutto-internal`

**X-Frame-Options Conflicts (Chrome Console Error)**
If you see "Refused to display in a frame because it set multiple 'X-Frame-Options' headers":
- This occurs when both Apache and n8n set conflicting X-Frame-Options headers
- The provided Apache configuration automatically resolves this by using `Header always unset X-Frame-Options` followed by setting `SAMEORIGIN`
- If you modify the Apache config, ensure you unset the header from the backend before setting your own

**Performance Issues**
- Monitor resource usage: `docker stats`
- Check n8n execution logs: `docker-compose logs n8n`
- Consider upgrading server specs if workflows are complex

### Log Locations
- Apache logs: `/var/log/apache2/`
- Let's Encrypt logs: `/var/log/letsencrypt/`
- Docker logs: `docker-compose logs [service]`

### Manual Certificate Generation
If automatic SSL setup fails:
```bash
sudo certbot --apache -d your-domain.com --email your-email@domain.com --agree-tos
```

## Development vs Production

This setup is optimized for production use with:
- Persistent volumes for data
- SSL certificates
- Security headers
- Database with health checks
- Automatic backups

For development, consider:
- Using HTTP instead of HTTPS
- Removing basic authentication
- Using bind mounts instead of volumes

## Support

### Getting Help
1. Check logs: `docker-compose logs`
2. Verify configuration: `sudo apache2ctl configtest`
3. Review setup script output
4. Check [n8n documentation](https://docs.n8n.io/)

### Contributing
1. Fork the repository
2. Create feature branch
3. Test your changes
4. Submit pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💼 About the Author

**Gilson Rincón**  
CEO and Co-founder of Solutto Consulting LLC

Gilson is a seasoned technology professional with extensive experience in business automation, ERP systems, and cloud infrastructure. He specializes in helping businesses optimize their operations through modern technology solutions.

**Connect with Gilson:**
- 🌐 Website: [https://www.soluttoconsulting.com](https://www.soluttoconsulting.com)
- 💼 LinkedIn: [Connect with Gilson Rincón](https://linkedin.com/in/gilson-rincon)
- 📧 Email: [gilson.rincon@soluttoconsulting.com](mailto:gilson.rincon@soluttoconsulting.com)

### 🤝 Professional Services

Need help with your n8n deployment or business automation? Solutto Consulting LLC offers:

- **n8n Custom Setup & Configuration**: Professional deployment and optimization
- **Workflow Development**: Custom automation workflows for your business needs
- **Integration Services**: Connect n8n with your existing business systems
- **Training & Support**: Team training and ongoing technical support
- **Cloud Infrastructure**: Complete hosting and infrastructure management

**Contact us for a consultation**: [https://www.soluttoconsulting.com/contact](https://www.soluttoconsulting.com/contact)

---

*© 2025 Solutto Consulting LLC. All rights reserved.*

## Acknowledgments

- [n8n](https://n8n.io/) - Workflow automation platform
- [Let's Encrypt](https://letsencrypt.org/) - Free SSL certificates
- [Docker](https://docker.com/) - Containerization platform
