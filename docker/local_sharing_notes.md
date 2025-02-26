# Wren AI Local Development and Sharing Guide

This document provides comprehensive instructions for setting up the Wren AI application for local development and sharing the containerized application with others.

## Table of Contents

1. [Local Development Setup](#local-development-setup)
   - [Prerequisites](#prerequisites)
   - [Initial Setup](#initial-setup)
   - [Running the Application](#running-the-application)
   - [Development Workflow](#development-workflow)
   - [Debugging](#debugging)

2. [Sharing with Others](#sharing-with-others)
   - [Option 1: Via Container Registry](#option-1-via-container-registry)
   - [Option 2: Portable Docker Compose Setup](#option-2-portable-docker-compose-setup)
   - [Option 3: Docker Save/Load for Air-gapped Environments](#option-3-docker-saveload-for-air-gapped-environments)
   - [Option 4: Development Environment Configuration Sharing](#option-4-development-environment-configuration-sharing)

## Local Development Setup

### Prerequisites

#### Required Software
- Docker Desktop (latest version recommended)
  - macOS: Docker Desktop for Mac
  - Windows: Docker Desktop for Windows with WSL2 backend
  - Linux: Docker Engine and Docker Compose
- Git
- Code editor (VSCode recommended)

#### System Requirements
- **CPU**: 4+ cores recommended
- **Memory**: Minimum 8GB (16GB recommended)
- **Disk Space**: At least 10GB free

### Initial Setup

#### 1. Clone the Repository
```bash
git clone https://github.com/your-org/Rohith-s-SQL.git
cd Rohith-s-SQL
```

#### 2. Create Configuration Files

Create a `.env` file in the project root:

```bash
cat > .env << EOL
WREN_PRODUCT_VERSION=dev
WREN_UI_VERSION=dev
WREN_BOOTSTRAP_VERSION=dev
WREN_AI_SERVICE_VERSION=dev
WREN_ENGINE_VERSION=latest
IBIS_SERVER_VERSION=latest
PLATFORM=$(uname -m | sed 's/x86_64/amd64/' | sed 's/arm64/arm64/')
WREN_ENGINE_PORT=50051
WREN_ENGINE_SQL_PORT=50052
WREN_AI_SERVICE_PORT=8000
IBIS_SERVER_PORT=8001
HOST_PORT=3000
AI_SERVICE_FORWARD_PORT=8000
PROJECT_DIR=$(pwd)
USER_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
TELEMETRY_ENABLED=false
GENERATION_MODEL=gpt-4
EXPERIMENTAL_ENGINE_RUST_VERSION=false
EOL
```

Copy the sample configuration:

```bash
cp docker/config.example.yaml config.yaml
```

Adjust `config.yaml` as needed for your local environment.

### Running the Application

#### Starting with Docker Compose

For development, use the development compose file:

```bash
cd docker
docker-compose -f docker-compose-dev.yaml up
```

This will:
1. Build or pull necessary Docker images
2. Create required volumes and networks
3. Start all services in development mode

#### Accessing the Application

- **Web UI**: http://localhost:3000
- **API Service**: http://localhost:8000
- **Health check endpoints**:
  - UI: http://localhost:3000/api/health
  - AI Service: http://localhost:8000/health

### Development Workflow

#### UI Development (wren-ui)

The wren-ui service is configured for hot reloading in development mode:

1. Make changes to files in the `wren-ui/src` directory
2. Changes will automatically be applied in the browser

For dependency changes:

```bash
# Stop docker compose
docker-compose -f docker-compose-dev.yaml down

# Update dependencies
cd ../wren-ui
yarn add new-package

# Restart docker compose
cd ../docker
docker-compose -f docker-compose-dev.yaml up --build wren-ui
```

#### AI Service Development (wren-ai-service)

For the Python-based AI service:

1. Make changes to the Python files in `wren-ai-service/src`
2. Restart the service to apply changes:
   ```bash
   docker-compose -f docker-compose-dev.yaml restart wren-ai-service
   ```

For dependency changes:

```bash
# Update Poetry dependencies
cd ../wren-ai-service
poetry add new-package

# Rebuild and restart the service
cd ../docker
docker-compose -f docker-compose-dev.yaml up --build wren-ai-service
```

### Debugging

#### Viewing Logs

View logs for all services:
```bash
docker-compose -f docker-compose-dev.yaml logs
```

Follow logs in real-time:
```bash
docker-compose -f docker-compose-dev.yaml logs -f
```

View logs for a specific service:
```bash
docker-compose -f docker-compose-dev.yaml logs wren-ui
```

#### Accessing Containers

Access a running container's shell:
```bash
docker-compose -f docker-compose-dev.yaml exec wren-ui /bin/sh
docker-compose -f docker-compose-dev.yaml exec wren-ai-service /bin/bash
```

#### Testing API Endpoints

Using curl:
```bash
curl http://localhost:8000/health
```

## Sharing with Others

There are multiple ways to share the Wren AI application with others, depending on your constraints and needs.

### Option 1: Via Container Registry

This is the recommended approach for most teams, using a container registry like Docker Hub, GitHub Container Registry, or AWS ECR.

#### Steps for the Provider

1. Build and push the images to your registry:

```bash
# Update the registry in the script if needed
export REGISTRY="your-registry"
./docker/deploy.sh
```

2. Share the version tag with recipients:

```bash
echo "The latest version is $(date +"%Y.%m.%d-%H%M")"
```

3. Prepare configuration files for sharing:

```bash
mkdir -p ~/wren-ai-share
VERSION=$(date +"%Y.%m.%d-%H%M")
cp docker/docker-compose.prod.yaml ~/wren-ai-share/docker-compose.yaml

# Create .env file
cat > ~/wren-ai-share/.env << EOL
WREN_PRODUCT_VERSION=${VERSION}
WREN_UI_VERSION=${VERSION}
WREN_BOOTSTRAP_VERSION=${VERSION}
WREN_AI_SERVICE_VERSION=${VERSION}
WREN_ENGINE_VERSION=latest
IBIS_SERVER_VERSION=latest
PLATFORM=linux/amd64
WREN_ENGINE_PORT=50051
WREN_ENGINE_SQL_PORT=50052
WREN_AI_SERVICE_PORT=8000
IBIS_SERVER_PORT=8001
HOST_PORT=3000
AI_SERVICE_FORWARD_PORT=8000
PROJECT_DIR=/opt/wren-ai
USER_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
TELEMETRY_ENABLED=false
GENERATION_MODEL=gpt-4
EXPERIMENTAL_ENGINE_RUST_VERSION=false
EOL

# Copy config
cp config.yaml ~/wren-ai-share/

# Create instructions
cat > ~/wren-ai-share/README.md << EOL
# Wren AI Setup Instructions

1. Install Docker and Docker Compose
2. Create a directory: \`mkdir -p ~/wren-ai && cd ~/wren-ai\`
3. Copy these files into that directory
4. Run: \`docker compose up -d\`
5. Access the application at http://localhost:3000
EOL
```

4. Share the configuration files with recipients via secure file sharing.

#### Steps for Recipients

1. Install Docker and Docker Compose
2. Create a directory: `mkdir -p ~/wren-ai && cd ~/wren-ai`
3. Place the received files in this directory
4. Run: `docker compose up -d`
5. Access the application at http://localhost:3000

### Option 2: Portable Docker Compose Setup

For scenarios where you want to share a ready-to-run configuration without using a registry.

#### Steps for the Provider

1. Create a development compose file with fixed image references:

```bash
mkdir -p ~/wren-ai-portable
cd ~/wren-ai-portable

# Copy and modify docker-compose file
cp /path/to/Rohith-s-SQL/docker/docker-compose-dev.yaml docker-compose.yaml

# Edit the file to use public images instead of local builds
# Replace build sections with image references from public repos
sed -i '' 's/build:/image: ghcr.io\/canner\//g' docker-compose.yaml

# Create .env file with public image tags
cat > .env << EOL
WREN_PRODUCT_VERSION=latest
WREN_UI_VERSION=latest
WREN_BOOTSTRAP_VERSION=latest
WREN_AI_SERVICE_VERSION=latest
WREN_ENGINE_VERSION=latest
IBIS_SERVER_VERSION=latest
PLATFORM=linux/amd64
WREN_ENGINE_PORT=50051
WREN_ENGINE_SQL_PORT=50052
WREN_AI_SERVICE_PORT=8000
IBIS_SERVER_PORT=8001
HOST_PORT=3000
AI_SERVICE_FORWARD_PORT=8000
PROJECT_DIR=\${PWD}
USER_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
TELEMETRY_ENABLED=false
GENERATION_MODEL=gpt-4
EXPERIMENTAL_ENGINE_RUST_VERSION=false
EOL

# Copy default config
cp /path/to/Rohith-s-SQL/config.yaml ./

# Create README
cat > README.md << EOL
# Wren AI Portable Setup

1. Install Docker and Docker Compose
2. Make sure you are in this directory
3. Run: \`docker compose up -d\`
4. Access the application at http://localhost:3000
EOL
```

2. Archive and share:

```bash
cd ~
tar -czvf wren-ai-portable.tgz wren-ai-portable/
```

#### Steps for Recipients

1. Install Docker and Docker Compose
2. Extract the archive: `tar -xzvf wren-ai-portable.tgz`
3. Navigate to directory: `cd wren-ai-portable`
4. Start the application: `docker compose up -d`
5. Access at http://localhost:3000

### Option 3: Docker Save/Load for Air-gapped Environments

For environments without internet access or where pulling from registries is restricted.

#### Steps for the Provider

1. Build all necessary images:

```bash
cd /path/to/Rohith-s-SQL
./docker/deploy.sh
```

2. Save the images to files:

```bash
VERSION=$(date +"%Y.%m.%d-%H%M")
REGISTRY="ghcr.io/canner"
mkdir -p ~/wren-ai-offline/images

# Save each image
docker save -o ~/wren-ai-offline/images/wren-ui.tar ${REGISTRY}/wren-ui:${VERSION}
docker save -o ~/wren-ai-offline/images/wren-bootstrap.tar ${REGISTRY}/wren-bootstrap:${VERSION}
docker save -o ~/wren-ai-offline/images/wren-ai-service.tar ${REGISTRY}/wren-ai-service:${VERSION}
docker save -o ~/wren-ai-offline/images/qdrant.tar qdrant/qdrant:v1.13.2

# Copy configuration files
cp docker/docker-compose.prod.yaml ~/wren-ai-offline/docker-compose.yaml

# Create .env file
cat > ~/wren-ai-offline/.env << EOL
WREN_PRODUCT_VERSION=${VERSION}
WREN_UI_VERSION=${VERSION}
WREN_BOOTSTRAP_VERSION=${VERSION}
WREN_AI_SERVICE_VERSION=${VERSION}
WREN_ENGINE_VERSION=latest
IBIS_SERVER_VERSION=latest
PLATFORM=linux/amd64
WREN_ENGINE_PORT=50051
WREN_ENGINE_SQL_PORT=50052
WREN_AI_SERVICE_PORT=8000
IBIS_SERVER_PORT=8001
HOST_PORT=3000
AI_SERVICE_FORWARD_PORT=8000
PROJECT_DIR=\${PWD}/data
USER_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
TELEMETRY_ENABLED=false
GENERATION_MODEL=gpt-4
EXPERIMENTAL_ENGINE_RUST_VERSION=false
EOL

# Copy config
cp config.yaml ~/wren-ai-offline/

# Create setup script
cat > ~/wren-ai-offline/setup.sh << 'EOL'
#!/bin/bash
set -e

# Create data directory
mkdir -p data

# Load Docker images
echo "Loading Docker images (this may take a while)..."
for image in images/*.tar; do
  echo "Loading $image..."
  docker load -i "$image"
done

# Start the application
echo "Starting Wren AI..."
docker-compose up -d

echo "Setup complete! Access the application at http://localhost:3000"
EOL
chmod +x ~/wren-ai-offline/setup.sh

# Create README
cat > ~/wren-ai-offline/README.md << EOL
# Wren AI Offline Setup

This package contains everything needed to run Wren AI without internet access.

## Requirements
- Docker and Docker Compose installed
- At least 10GB free disk space
- At least 8GB RAM

## Setup Instructions
1. Extract this archive
2. Navigate to the extracted directory
3. Run: \`./setup.sh\`
4. Access the application at http://localhost:3000
EOL
```

3. Archive and share:

```bash
cd ~
tar -czvf wren-ai-offline-package.tgz wren-ai-offline/
```

#### Steps for Recipients

1. Install Docker and Docker Compose
2. Extract the archive: `tar -xzvf wren-ai-offline-package.tgz`
3. Navigate to directory: `cd wren-ai-offline`
4. Run the setup script: `./setup.sh`
5. Access the application at http://localhost:3000

### Option 4: Development Environment Configuration Sharing

For development teams where each member will build their own images but should use consistent configuration.

#### Steps for the Provider

1. Create a development environment configuration package:

```bash
mkdir -p ~/wren-ai-dev-setup
cd /path/to/Rohith-s-SQL

# Copy essential files
cp docker/docker-compose-dev.yaml ~/wren-ai-dev-setup/docker-compose.yaml
cp config.yaml ~/wren-ai-dev-setup/
cp -r wren-ui/public/sample-data ~/wren-ai-dev-setup/sample-data

# Create template .env
cat > ~/wren-ai-dev-setup/.env.template << EOL
WREN_PRODUCT_VERSION=dev
WREN_UI_VERSION=dev
WREN_BOOTSTRAP_VERSION=dev
WREN_AI_SERVICE_VERSION=dev
WREN_ENGINE_VERSION=latest
IBIS_SERVER_VERSION=latest
PLATFORM=linux/amd64
WREN_ENGINE_PORT=50051
WREN_ENGINE_SQL_PORT=50052
WREN_AI_SERVICE_PORT=8000
IBIS_SERVER_PORT=8001
HOST_PORT=3000
AI_SERVICE_FORWARD_PORT=8000
PROJECT_DIR=/path/to/your/cloned/repo
USER_UUID=generate-your-own-uuid
TELEMETRY_ENABLED=false
GENERATION_MODEL=gpt-4
EXPERIMENTAL_ENGINE_RUST_VERSION=false
EOL

# Create setup script
cat > ~/wren-ai-dev-setup/setup.sh << 'EOL'
#!/bin/bash
set -e

# Check if git is installed
if ! command -v git &> /dev/null; then
  echo "Git is not installed. Please install git and try again."
  exit 1
fi

# Prompt for repository URL
read -p "Enter the Git repository URL: " REPO_URL
read -p "Enter the directory where you want to clone the repository: " REPO_DIR

# Clone the repository
mkdir -p "$REPO_DIR"
git clone "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR"

# Create .env file
UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
sed "s|PROJECT_DIR=/path/to/your/cloned/repo|PROJECT_DIR=$(pwd)|g" ../.env.template > .env
sed -i "" "s|USER_UUID=generate-your-own-uuid|USER_UUID=$UUID|g" .env

# Copy config
cp ../config.yaml ./

# Handle platform-specific settings
PLATFORM=$(uname -m | sed 's/x86_64/amd64/' | sed 's/arm64/arm64/')
sed -i "" "s|PLATFORM=linux/amd64|PLATFORM=$PLATFORM|g" .env

echo "Setup complete! To start the application:"
echo "cd $REPO_DIR/docker"
echo "docker-compose -f docker-compose-dev.yaml up"
EOL
chmod +x ~/wren-ai-dev-setup/setup.sh

# Create README
cat > ~/wren-ai-dev-setup/README.md << EOL
# Wren AI Development Setup

This package helps you set up a development environment for Wren AI.

## Prerequisites
- Git
- Docker and Docker Compose
- Access to the Wren AI repository

## Setup Instructions
1. Run: \`./setup.sh\`
2. Follow the prompts to complete the setup
3. Start the application as instructed at the end of the setup

## Manual Setup
If the automatic setup doesn't work:
1. Clone the repository
2. Copy \`.env.template\` to your cloned repo as \`.env\`
3. Edit the \`.env\` file to update the paths and generate a UUID
4. Copy \`config.yaml\` to your cloned repo
5. Start the application with Docker Compose
EOL
```

2. Archive and share:

```bash
cd ~
tar -czvf wren-ai-dev-setup.tgz wren-ai-dev-setup/
```

#### Steps for Recipients

1. Install prerequisites: Git, Docker, Docker Compose
2. Extract the setup archive: `tar -xzvf wren-ai-dev-setup.tgz`
3. Navigate to the directory: `cd wren-ai-dev-setup`
4. Run the setup script: `./setup.sh`
5. Follow the prompts to complete setup
6. Start the application as instructed

This approach allows each developer to have their own working copy of the codebase while ensuring consistent configuration across the team.