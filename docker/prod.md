# Production Deployment Guide

This guide outlines the steps to deploy the Wren application stack in a production environment.

## Prerequisites

- Docker Engine 20.10.0 or later
- Docker Compose v2.0.0 or later
- Access to the GitHub Container Registry (ghcr.io)
- Production server with at least 4GB RAM and 2 CPUs
- Domain name (optional but recommended)

## Directory Structure

```
docker/
├── docker-compose.prod.yaml    # Production compose file
├── .env.production            # Production environment variables
├── .dockerignore             # Files to exclude from builds
└── prod.md                   # This deployment guide
```

## Deployment Steps

### 1. Environment Setup

1. Copy the production environment file:
   ```bash
   cp .env.production .env
   ```

2. Edit the `.env` file and update the following critical values:
   - Replace all placeholder API keys with actual production keys:
     - `LLM_OPENAI_API_KEY`
     - `EMBEDDER_OPENAI_API_KEY`
     - `LLM_AZURE_OPENAI_API_KEY` (if using Azure)
     - `EMBEDDER_AZURE_OPENAI_API_KEY` (if using Azure)
     - `QDRANT_API_KEY`
     - `POSTHOG_API_KEY`
     - `LANGFUSE_SECRET_KEY`
     - `LANGFUSE_PUBLIC_KEY`
   - Generate and set a unique `USER_UUID`
   - Adjust ports if needed (`HOST_PORT`, `AI_SERVICE_FORWARD_PORT`)

### 2. Network and Security Setup

1. Create a dedicated network for the application:
   ```bash
   docker network create wren
   ```

2. Set up firewall rules (if using UFW):
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

### 3. Data Volumes and Persistence

1. Create named volumes for persistent data:
   ```bash
   docker volume create wren_data
   ```

### 4. Deployment

1. Pull the latest images:
   ```bash
   docker compose -f docker-compose.prod.yaml pull
   ```

2. Start the services:
   ```bash
   docker compose -f docker-compose.prod.yaml up -d
   ```

3. Verify all services are running:
   ```bash
   docker compose -f docker-compose.prod.yaml ps
   ```

4. Check service health:
   ```bash
   docker compose -f docker-compose.prod.yaml ps --format "table {{.Name}}\t{{.Status}}"
   ```

### 5. Health Checks and Monitoring

The following health check endpoints are available:
- Wren Engine: `http://localhost:8080/health`
- Wren AI Service: `http://localhost:5555/health`
- Ibis Server: `http://localhost:8000/health`
- Wren UI: `http://localhost:3000/api/health`
- Qdrant: `http://localhost:6333/health`

### 6. Logging

All services are configured with JSON logging and log rotation:
- Max file size: 10MB
- Max number of files: 3

To view logs:
```bash
# All services
docker compose -f docker-compose.prod.yaml logs

# Specific service
docker compose -f docker-compose.prod.yaml logs [service-name]

# Follow logs
docker compose -f docker-compose.prod.yaml logs -f
```

### 7. Updating the Application

To update services:

1. Pull new images:
   ```bash
   docker compose -f docker-compose.prod.yaml pull
   ```

2. Update specific service:
   ```bash
   docker compose -f docker-compose.prod.yaml up -d --no-deps [service-name]
   ```

3. Update all services:
   ```bash
   docker compose -f docker-compose.prod.yaml up -d
   ```

### 8. Backup and Restore

1. Backup volumes:
   ```bash
   docker run --rm -v wren_data:/data -v $(pwd)/backup:/backup alpine tar czf /backup/data.tar.gz /data
   ```

2. Restore volumes:
   ```bash
   docker run --rm -v wren_data:/data -v $(pwd)/backup:/backup alpine sh -c "cd /data && tar xvf /backup/data.tar.gz --strip 1"
   ```

### 9. Performance Tuning

The following performance settings are configured in `.env`:
- Max concurrent requests: 50
- Response timeout: 30 seconds
- Rate limiting: 1000 requests per 15 minutes

Adjust these values based on your server capacity and requirements.

### 10. Security Best Practices

1. All services run with least privileges
2. Sensitive volumes mounted as read-only where possible
3. Services bound to localhost where appropriate
4. Rate limiting enabled for API endpoints
5. Regular security updates for base images
6. No sensitive data in image layers

### 11. Troubleshooting

Common issues and solutions:

1. Service won't start:
   ```bash
   docker compose -f docker-compose.prod.yaml logs [service-name]
   ```

2. Check resource usage:
   ```bash
   docker stats
   ```

3. Verify network connectivity:
   ```bash
   docker network inspect wren
   ```

### 12. Monitoring and Alerts

1. Health check monitoring is configured for all services
2. Failed health checks will trigger container restarts
3. Log monitoring is enabled with rotation
4. Use `docker events` to monitor container lifecycle events

### 13. Cleanup

To remove unused resources:
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune
```

## Support and Maintenance

For production support:
1. Check service logs for errors
2. Verify health check endpoints
3. Monitor resource usage
4. Keep all images updated
5. Regularly backup data volumes

## Additional Resources

- [Docker Production Best Practices](https://docs.docker.com/compose/production/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Security Guidelines](https://docs.docker.com/engine/security/) 