#!/bin/bash
set -e

# Configuration - Update these variables
REGISTRY="ghcr.io/canner"  # Replace with your container registry
APP_VERSION=$(date +"%Y.%m.%d-%H%M")
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}====== Wren AI Deployment Script ======${NC}"
echo "Deploying version: ${APP_VERSION}"

# Ensure .env file exists
if [ ! -f "${ENV_FILE}" ]; then
    echo -e "${RED}Error: .env file not found at ${ENV_FILE}${NC}"
    echo "Please create the .env file with required environment variables"
    exit 1
fi

# Export all variables from .env file
export $(grep -v '^#' ${ENV_FILE} | xargs)

# Building images
echo -e "${YELLOW}Building Docker images...${NC}"

# Build wren-ui
echo "Building wren-ui..."
docker build -t ${REGISTRY}/wren-ui:${APP_VERSION} -f ${PROJECT_ROOT}/wren-ui/Dockerfile ${PROJECT_ROOT}/wren-ui

# Build wren-bootstrap (if needed)
echo "Building wren-bootstrap..."
docker build -t ${REGISTRY}/wren-bootstrap:${APP_VERSION} -f ${PROJECT_ROOT}/docker/bootstrap/Dockerfile ${PROJECT_ROOT}/docker/bootstrap

# Build wren-ai-service
echo "Building wren-ai-service..."
docker build -t ${REGISTRY}/wren-ai-service:${APP_VERSION} -f ${PROJECT_ROOT}/wren-ai-service/docker/Dockerfile ${PROJECT_ROOT}/wren-ai-service

echo -e "${GREEN}All images built successfully!${NC}"

# Push images to registry
echo -e "${YELLOW}Pushing images to registry...${NC}"

# Check if user is logged into the registry
if ! docker info | grep -q "${REGISTRY}"; then
    echo -e "${YELLOW}Please log in to the container registry (${REGISTRY})${NC}"
    echo "You can do this with: docker login ${REGISTRY}"
    read -p "Press Enter after you've logged in..."
fi

docker push ${REGISTRY}/wren-ui:${APP_VERSION}
docker push ${REGISTRY}/wren-bootstrap:${APP_VERSION}
docker push ${REGISTRY}/wren-ai-service:${APP_VERSION}

echo -e "${GREEN}Images pushed successfully!${NC}"

# Update version in .env file for deployment
echo -e "${YELLOW}Updating version references...${NC}"

# Create a deployment directory if it doesn't exist
DEPLOY_DIR="${PROJECT_ROOT}/deployment/releases/${APP_VERSION}"
mkdir -p ${DEPLOY_DIR}

# Create production .env file with new versions
cat <<EOF > ${DEPLOY_DIR}/.env
WREN_PRODUCT_VERSION=${APP_VERSION}
WREN_UI_VERSION=${APP_VERSION}
WREN_BOOTSTRAP_VERSION=${APP_VERSION}
WREN_AI_SERVICE_VERSION=${APP_VERSION}
WREN_ENGINE_VERSION=${WREN_ENGINE_VERSION:-latest}
IBIS_SERVER_VERSION=${IBIS_SERVER_VERSION:-latest}
PLATFORM=${PLATFORM:-linux/amd64}
WREN_ENGINE_PORT=${WREN_ENGINE_PORT:-50051}
WREN_ENGINE_SQL_PORT=${WREN_ENGINE_SQL_PORT:-50052}
WREN_AI_SERVICE_PORT=${WREN_AI_SERVICE_PORT:-8000}
IBIS_SERVER_PORT=${IBIS_SERVER_PORT:-8001}
HOST_PORT=${HOST_PORT:-3000}
AI_SERVICE_FORWARD_PORT=${AI_SERVICE_FORWARD_PORT:-8000}
PROJECT_DIR=${PROJECT_DIR:-/opt/wren-ai}
USER_UUID=${USER_UUID}
POSTHOG_API_KEY=${POSTHOG_API_KEY}
POSTHOG_HOST=${POSTHOG_HOST}
TELEMETRY_ENABLED=${TELEMETRY_ENABLED:-false}
GENERATION_MODEL=${GENERATION_MODEL:-gpt-4}
EXPERIMENTAL_ENGINE_RUST_VERSION=${EXPERIMENTAL_ENGINE_RUST_VERSION:-false}
EOF

# Copy production docker-compose file
cp ${PROJECT_ROOT}/docker/docker-compose.prod.yaml ${DEPLOY_DIR}/docker-compose.yaml

# Create deployment instructions
cat <<EOF > ${DEPLOY_DIR}/deploy.sh
#!/bin/bash
set -e

# Deploy the wren-ai stack

# 1. Create the application directory if it doesn't exist
mkdir -p /opt/wren-ai/data

# 2. Copy configuration
cp -n config.yaml /opt/wren-ai/config.yaml 2>/dev/null || true

# 3. Set environment variables
set -a
source ./.env
set +a

# 4. Start the services
docker-compose up -d

echo "Deployment completed successfully!"
echo "UI should be accessible at http://localhost:\${HOST_PORT}"
EOF
chmod +x ${DEPLOY_DIR}/deploy.sh

# Create sample config file if it doesn't exist
cp -n ${PROJECT_ROOT}/config.yaml ${DEPLOY_DIR}/config.yaml 2>/dev/null || true

echo -e "${GREEN}Deployment package created at: ${DEPLOY_DIR}${NC}"
echo ""
echo -e "${YELLOW}To deploy to your server:${NC}"
echo "1. Copy the entire ${DEPLOY_DIR} directory to your server"
echo "2. Navigate to the directory on your server"
echo "3. Run: ./deploy.sh"
echo ""
echo -e "${GREEN}Done!${NC}"