# Keygen Docker Deployment

> Complete Docker-based deployment solution for Keygen API with Caddy reverse proxy, PostgreSQL database, and Redis cache.

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://docker.com)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-v2.0+-blue.svg)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd keygen-docker

# 2. Create environment file
cp .env.example .env
# Edit .env with your configuration

# 3. Make startup script executable
chmod +x start_keygen.sh

# 4. Deploy everything
./start_keygen.sh
```

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)
- [Contributing](#contributing)

## 🔧 Prerequisites

- **Docker Engine**: 20.10+
- **Docker Compose**: v2.0+ (or docker-compose v1.29+)
- **Domain Name**: Configured to point to your server
- **Server**: Ubuntu 20.04+ with 2GB+ RAM, 10GB+ storage
- **Ports**: 80 and 443 available

### Install Docker (Ubuntu/Debian)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login, then verify
docker --version
docker compose version
```

## 📁 Project Structure

```
keygen-docker/
├── 📄 docker-compose.yml    # Main Docker Compose configuration
├── 🚀 start_keygen.sh      # Automated setup script
├── ⚙️ .env                 # Environment variables (create this)
├── 🌐 Caddyfile           # Generated automatically
├── 📚 README.md           # This file
└── 📝 .env.example        # Environment template
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file with the following configuration:

```bash
# Domain Configuration
HOST_DOMAIN=api.yourdomain.com
ADMIN_EMAIL=your-email@yourdomain.com

# Keygen Configuration
KEYGEN_HOST=https://api.yourdomain.com
KEYGEN_ADMIN_EMAIL=admin@yourdomain.com
KEYGEN_ADMIN_PASSWORD=your-super-secure-password

# Database Configuration
POSTGRES_USER=keygen
POSTGRES_PASSWORD=change-this-secure-password
POSTGRES_DB=keygen_production

# Optional: Advanced Settings
KEYGEN_ENVIRONMENT=production
KEYGEN_SECRET_KEY_BASE=generate-a-long-random-string-here
KEYGEN_REDIS_URL=redis://redis:6379/0
```

### Generate Secure Values

```bash
# Generate secure password
openssl rand -base64 32

# Generate secret key base
openssl rand -hex 64
```

### DNS Configuration

Configure your domain DNS:

```
A Record: api.yourdomain.com → YOUR_SERVER_IP
A Record: health.yourdomain.com → YOUR_SERVER_IP
```

## 🚀 Installation

### Step 1: Server Setup

```bash
# Create project directory
mkdir keygen-deployment
cd keygen-deployment

# Download/clone project files
# Ensure you have: docker-compose.yml, start_keygen.sh
```

### Step 2: Configuration

```bash
# Create environment file
nano .env
# Add your configuration (see Configuration section above)

# Make startup script executable
chmod +x start_keygen.sh
```

### Step 3: Deployment

```bash
# Run automated setup
./start_keygen.sh
```

The script will:
- ✅ Generate Caddyfile configuration
- ✅ Start PostgreSQL and Redis databases
- ✅ Run Keygen initialization
- ✅ Start all services with health checks
- ✅ Configure SSL certificates automatically
- ✅ Verify API functionality

### Step 4: Verification

```bash
# Check service status
docker compose ps

# Test API endpoints
curl -I https://api.yourdomain.com/v1/health
curl -I https://health.yourdomain.com

# View setup completion message
# Look for "Keygen Setup Complete!" message
```

## 🏗️ Architecture

### Services Overview

| Service | Description | Port | Health Check |
|---------|-------------|------|--------------|
| `keygen-web` | Main API server | 3000 | `/v1/health` |
| `keygen-worker` | Background jobs | - | - |
| `postgres` | Database | 5432 | `pg_isready` |
| `redis` | Cache/sessions | 6379 | `ping` |
| `caddy` | Reverse proxy | 80,443 | - |

### Profiles

- **`config`**: Generates Caddyfile
- **`setup`**: One-time initialization

### Volumes

- `postgres_data`: Database storage
- `redis_data`: Redis persistence
- `caddy_data`: SSL certificates
- `caddy_config`: Caddy configuration
- `caddy_logs`: Access logs

## 💻 Usage

### Basic Operations

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### Individual Service Management

```bash
# Generate Caddyfile only
docker compose --profile config run --rm caddy-config

# Run setup only
docker compose --profile setup run --rm setup

# Start specific services
docker compose up -d postgres redis
docker compose up -d keygen-web keygen-worker
```

### API Testing

```bash
# Health check
curl https://api.yourdomain.com/v1/health

# Create license (replace tokens/IDs)
curl -X POST https://api.yourdomain.com/v1/accounts/ACCOUNT_ID/licenses \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{
    "data": {
      "type": "licenses",
      "attributes": {"name": "Test License"},
      "relationships": {
        "policy": {"data": {"type": "policies", "id": "POLICY_ID"}}
      }
    }
  }'
```

## 🔍 Troubleshooting

### Common Issues

<details>
<summary><strong>🔴 Caddyfile Generation Fails</strong></summary>

```bash
# Check environment variables
cat .env | grep -E "(HOST_DOMAIN|ADMIN_EMAIL)"

# Set manually and retry
export HOST_DOMAIN="api.yourdomain.com"
export ADMIN_EMAIL="your-email@yourdomain.com"
docker compose --profile config run --rm caddy-config
```
</details>

<details>
<summary><strong>🔴 SSL Certificate Issues</strong></summary>

```bash
# Check DNS resolution
dig api.yourdomain.com

# View Caddy logs
docker compose logs caddy

# Test HTTP first
curl -I http://api.yourdomain.com
```
</details>

<details>
<summary><strong>🔴 Database Connection Issues</strong></summary>

```bash
# Check PostgreSQL health
docker compose exec postgres pg_isready -U keygen -d keygen_production

# View database logs
docker compose logs postgres

# Reset database (⚠️ destroys data)
docker compose down -v
docker volume prune
```
</details>

<details>
<summary><strong>🔴 API Not Responding</strong></summary>

```bash
# Check Keygen web service
docker compose exec keygen-web wget --spider http://localhost:3000/v1/health

# View application logs
docker compose logs keygen-web

# Restart service
docker compose restart keygen-web
```
</details>

### Health Checks

```bash
# Service health
docker compose ps

# API health
curl http://localhost:3000/v1/health

# Database connectivity
docker compose exec postgres psql -U keygen -d keygen_production -c "SELECT version();"

# Redis connectivity
docker compose exec redis redis-cli ping
```

### Log Analysis

```bash
# View recent logs
docker compose logs --tail=100

# Service-specific logs
docker compose logs keygen-web
docker compose logs caddy
docker compose logs postgres

# Save logs to file
docker compose logs > keygen-logs-$(date +%Y%m%d).txt
```

## 🔧 Maintenance

### Backups

```bash
# Database backup
docker compose exec postgres pg_dump -U keygen keygen_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup
ls -lh backup_*.sql
```

### Updates

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d --force-recreate

# Clean up old images
docker image prune -f
```

### Monitoring

```bash
# Resource usage
docker stats

# Disk usage
docker system df

# Service status
docker compose ps
```

### Security Maintenance

```bash
# Rotate admin password
# 1. Update .env file
# 2. Restart services
docker compose restart keygen-web

# Update SSL certificates (automatic via Caddy)
docker compose restart caddy

# Review access logs
docker compose exec caddy cat /var/log/caddy/keygen.log
```

## 🔒 Security Considerations

- **Environment Variables**: Never commit `.env` to version control
- **Database Passwords**: Use strong, unique passwords (32+ characters)
- **Admin Credentials**: Change immediately after setup
- **Firewall**: Only expose ports 80/443 externally
- **Updates**: Regularly update Docker images
- **Access Logs**: Monitor for suspicious activity
- **SSL/TLS**: Certificates auto-renewed by Caddy

## 📊 Production Checklist

Before going live:

- [ ] DNS properly configured and propagated
- [ ] SSL certificates successfully issued
- [ ] Database backup strategy implemented
- [ ] Monitoring and alerting set up
- [ ] Firewall rules configured
- [ ] Admin credentials changed from defaults
- [ ] API endpoints tested
- [ ] Log rotation configured
- [ ] Resource limits appropriate for load

## 🆘 Support & Resources

### Quick Commands Reference

```bash
# 🚀 Deploy everything
./start_keygen.sh

# 📊 Check status
docker compose ps

# 📝 View logs
docker compose logs -f

# 🔄 Restart services
docker compose restart

# 🧹 Clean shutdown
docker compose down

# 💾 Backup database
docker compose exec postgres pg_dump -U keygen keygen_production > backup.sql

# 🔧 Access container shell
docker compose exec keygen-web sh
```

### Environment Template

Create `.env.example`:

```bash
# Copy this to .env and update values
HOST_DOMAIN=api.example.com
ADMIN_EMAIL=admin@example.com
KEYGEN_HOST=https://api.example.com
KEYGEN_ADMIN_EMAIL=admin@example.com
KEYGEN_ADMIN_PASSWORD=change-this-password
POSTGRES_USER=keygen
POSTGRES_PASSWORD=change-this-password
POSTGRES_DB=keygen_production
```

### Getting Help

1. **Documentation**: [Keygen Official Docs](https://keygen.sh/docs/)
2. **Docker Issues**: Check `docker compose logs`
3. **SSL Issues**: Verify DNS and check Caddy logs
4. **Database Issues**: Check PostgreSQL logs and connectivity
5. **Network Issues**: Verify ports 80/443 accessibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**⭐ Star this repository if it helped you deploy Keygen successfully!**
