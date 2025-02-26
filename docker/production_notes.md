# Wren AI Production Deployment Guide

This document provides detailed instructions on how to deploy the Wren AI application to a production environment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Build and Package the Application](#build-and-package-the-application)
3. [Server Setup](#server-setup)
4. [Deployment Process](#deployment-process)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting the deployment process, ensure you have:

### Required Software
- Docker Engine (20.10.x or newer)
- Docker Compose (v2.x or newer)
- Git (optional, for version control)
- SSH access to your production server

### Hardware Requirements
- **CPU**: At least 4 cores (8 recommended)
- **Memory**: Minimum 10GB RAM (16GB recommended)
  - Bootstrap: 128MB
  - Wren Engine: 2GB
  - Ibis Server: 1GB
  - Wren AI Service: 4GB
  - Qdrant: 2GB
  - Wren UI: 1GB
- **Disk Space**: At least 20GB of free space (40GB recommended)
- **Network**: Stable internet connection

### Access Requirements
- Access to your container registry (ghcr.io/canner or your own registry)
- Authentication credentials for the registry

## Build and Package the Application

### Setting Up Environment Variables

1. Create a `.env` file in the project root with required configuration:

```bash
# Core versions
WREN_ENGINE_VERSION=latest
IBIS_SERVER_VERSION=latest

# System configuration
PLATFORM=linux/amd64 # or arm64 for ARM-based servers
PROJECT_DIR=/opt/wren-ai

# Service ports
WREN_ENGINE_PORT=50051
WREN_ENGINE_SQL_PORT=50052
WREN_AI_SERVICE_PORT=8000
IBIS_SERVER_PORT=8001
HOST_PORT=3000
AI_SERVICE_FORWARD_PORT=8000

# Application settings
USER_UUID=your-uuid-here # Generate with uuidgen command
TELEMETRY_ENABLED=false
GENERATION_MODEL=gpt-4 # or your preferred model
EXPERIMENTAL_ENGINE_RUST_VERSION=false

# Optional telemetry settings
POSTHOG_API_KEY=your-api-key-here
POSTHOG_HOST=app.posthog.com
```

### Building Docker Images

Run the deployment script to build, tag, and push the Docker images:

```bash
cd /path/to/Rohith-s-SQL
./docker/deploy.sh
```

This script will:

1. Build Docker images for all services
   - wren-ui
   - wren-bootstrap
   - wren-ai-service
2. Tag images with a timestamp-based version (YYYY.MM.DD-HHMM)
3. Push images to the container registry
4. Create a deployment package in `deployment/releases/YYYY.MM.DD-HHMM/`

### Deployment Package Contents

The script generates a complete deployment package that includes:
- `docker-compose.yaml`: Production-ready compose file
- `.env`: Environment variables for deployment
- `config.yaml`: Application configuration
- `deploy.sh`: Server-side deployment script

## Server Setup

### Operating System Requirements
- Linux (Ubuntu 20.04 LTS or newer recommended)
- Kernel version 5.4 or newer

### Prepare the Server

1. Update the system:
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

2. Install Docker and Docker Compose:
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Install Docker Compose
   sudo apt-get install docker-compose-plugin
   
   # Add your user to the docker group
   sudo usermod -aG docker $USER
   ```

3. Log out and log back in to apply group changes, or run:
   ```bash
   newgrp docker
   ```

4. Create the application directory:
   ```bash
   sudo mkdir -p /opt/wren-ai
   sudo chown $USER:$USER /opt/wren-ai
   ```

## Deployment Process

### Transfer Deployment Package

1. Copy the deployment package to your server:
   ```bash
   # Replace with your actual version and server details
   scp -r /path/to/Rohith-s-SQL/deployment/releases/YYYY.MM.DD-HHMM/ user@your-server:/tmp/
   ```

2. SSH into your server:
   ```bash
   ssh user@your-server
   ```

3. Move the deployment files:
   ```bash
   mv /tmp/YYYY.MM.DD-HHMM/ /opt/wren-ai/current
   cd /opt/wren-ai/current
   ```

### Deploy the Application

1. Review and possibly edit the configuration files:
   - `.env` - Check environment variables
   - `config.yaml` - Adjust application settings if needed

2. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

3. Verify all services are running:
   ```bash
   docker compose ps
   ```

   All services should show as "running" and health checks should pass.

## Post-Deployment Configuration

### Set Up a Reverse Proxy (Nginx)

1. Install Nginx:
   ```bash
   sudo apt-get install -y nginx
   ```

2. Create a server configuration file:
   ```bash
   sudo nano /etc/nginx/sites-available/wren-ai
   ```

3. Add the following configuration:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       
       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

4. Enable the site and restart Nginx:
   ```bash
   sudo ln -s /etc/nginx/sites-available/wren-ai /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

### Configure SSL with Let's Encrypt

1. Install Certbot:
   ```bash
   sudo apt-get install -y certbot python3-certbot-nginx
   ```

2. Obtain SSL certificate:
   ```bash
   sudo certbot --nginx -d your-domain.com
   ```

3. Configure Certbot to auto-renew certificates:
   ```bash
   sudo systemctl status certbot.timer
   ```

### Setup Firewall Rules

1. Allow necessary ports:
   ```bash
   sudo ufw allow ssh
   sudo ufw allow http
   sudo ufw allow https
   sudo ufw enable
   ```

## Monitoring and Maintenance

### View Service Logs

To view logs from all services:
```bash
cd /opt/wren-ai/current
docker compose logs
```

To view logs for a specific service:
```bash
docker compose logs wren-ui
docker compose logs wren-ai-service
```

To follow logs in real-time:
```bash
docker compose logs -f
```

### Check Service Health

Check all services status:
```bash
docker compose ps
```

Detailed health check:
```bash
docker compose exec wren-ui curl -f http://localhost:3000/api/health
docker compose exec wren-ai-service curl -f http://localhost:8000/health
```

### Backup Data

Create a backup of the persistent data volume:
```bash
cd /opt/wren-ai/current
docker compose down
sudo tar -czvf wren-ai-data-backup-$(date +%F).tar.gz /opt/wren-ai/data
docker compose up -d
```

### Update the Application

To update to a new version:
1. Follow the build and package steps for the new version
2. Transfer the new deployment package to the server
3. Stop the current deployment:
   ```bash
   cd /opt/wren-ai/current
   docker compose down
   ```
4. Create a backup of your data
5. Move to the new deployment and start it:
   ```bash
   cd /opt/wren-ai/new-version
   ./deploy.sh
   ```

## Troubleshooting

### Common Issues and Solutions

**Issue: Services fail to start**
- Check logs: `docker compose logs <service-name>`
- Verify container resources: `docker stats`
- Check environment variables: Review `.env` file

**Issue: Health checks failing**
- Examine the health check logs: `docker inspect <container-id> | grep -A 10 "Health"`
- Check container connectivity: `docker compose exec wren-ui ping wren-engine`

**Issue: Networking problems**
- Verify network creation: `docker network ls`
- Check network settings: `docker network inspect wren_wren`
- Ensure services are on the same network: `docker inspect <container-id>`

**Issue: Performance issues**
- Check resource usage: `docker stats`
- Review logs for errors: `docker compose logs`
- Adjust memory limits in docker-compose.yaml if needed

### Recovery Procedures

**Recovering from data corruption**:
1. Stop the stack: `docker compose down`
2. Restore from backup: `sudo tar -xzvf wren-ai-data-backup.tar.gz -C /`
3. Restart: `docker compose up -d`

**Complete reset**:
1. Stop and remove all containers: `docker compose down -v`
2. Remove all data: `sudo rm -rf /opt/wren-ai/data/*`
3. Redeploy: `./deploy.sh`