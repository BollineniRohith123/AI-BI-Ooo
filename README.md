# AI-BI-Ooo

A production-ready AI-powered Business Intelligence application with Docker deployment configuration.

## Overview

This repository contains the Docker configuration and deployment guides for running the AI-BI-Ooo application stack in production. The application consists of multiple services including a UI component, AI service, database, and various supporting services.

## Architecture

The application stack includes:
- Wren UI (Frontend)
- Wren Engine (Backend)
- Wren AI Service (AI Processing)
- Ibis Server (Data Processing)
- Qdrant (Vector Database)
- Bootstrap Service (Initialization)

## Prerequisites

- Docker Engine 20.10.0 or later
- Docker Compose v2.0.0 or later
- Git
- 4GB RAM minimum
- 2 CPUs minimum
- Access to GitHub Container Registry (ghcr.io)

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/BollineniRohith123/AI-BI-Ooo.git
   cd AI-BI-Ooo
   ```

2. Set up environment:
   ```bash
   cd docker
   cp .env.production .env
   ```

3. Configure environment variables:
   - Open `.env` in your preferred editor
   - Update all API keys and configuration values
   - Generate and set a unique USER_UUID

4. Create Docker network:
   ```bash
   docker network create wren
   ```

5. Start the application:
   ```bash
   docker compose -f docker-compose.prod.yaml up -d
   ```

6. Verify deployment:
   ```bash
   docker compose -f docker-compose.prod.yaml ps
   ```

## Detailed Setup

For detailed setup instructions, please refer to the [Production Deployment Guide](docker/prod.md).

## Configuration

### Environment Variables

Key environment variables that need to be configured:

```env
# API Keys
LLM_OPENAI_API_KEY=your_production_openai_key
EMBEDDER_OPENAI_API_KEY=your_production_openai_key
QDRANT_API_KEY=your_production_qdrant_key

# Service Configuration
HOST_PORT=80
AI_SERVICE_FORWARD_PORT=5555

# Performance Settings
MAX_CONCURRENT_REQUESTS=50
RESPONSE_TIMEOUT_MS=30000
```

### Ports

Default port mappings:
- UI: 80
- AI Service: 5555
- Engine: 8080
- Ibis Server: 8000
- Qdrant: 6333

## Health Checks

Monitor service health at these endpoints:
- `http://localhost:8080/health` - Wren Engine
- `http://localhost:5555/health` - AI Service
- `http://localhost:8000/health` - Ibis Server
- `http://localhost:3000/api/health` - UI
- `http://localhost:6333/health` - Qdrant

## Maintenance

### Logs

View service logs:
```bash
# All services
docker compose -f docker-compose.prod.yaml logs

# Specific service
docker compose -f docker-compose.prod.yaml logs [service-name]
```

### Updates

Update services:
```bash
docker compose -f docker-compose.prod.yaml pull
docker compose -f docker-compose.prod.yaml up -d
```

### Backup

Backup data:
```bash
docker run --rm -v wren_data:/data -v $(pwd)/backup:/backup \
  alpine tar czf /backup/data.tar.gz /data
```

## Security

- All services run with least privileges
- Sensitive volumes mounted as read-only
- Rate limiting enabled
- Regular security updates
- No sensitive data in image layers

## Troubleshooting

Common issues and solutions are documented in the [Production Deployment Guide](docker/prod.md#troubleshooting).

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and issues:
1. Check the [Production Deployment Guide](docker/prod.md)
2. Open an issue in the repository
3. Check service logs and health endpoints

## Acknowledgments

- Docker and Docker Compose teams
- OpenAI for AI capabilities
- Qdrant for vector database
- All contributors and maintainers
