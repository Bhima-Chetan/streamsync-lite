#!/bin/bash

# StreamSync Lite - AWS Deployment Script
# Usage: ./deploy.sh [EC2_IP] [KEY_FILE]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
EC2_IP=${1:-""}
KEY_FILE=${2:-""}
REMOTE_USER="ec2-user"
APP_NAME="streamsync-api"
DOCKER_IMAGE="streamsync-backend"

echo -e "${GREEN}🚀 StreamSync Lite Deployment Script${NC}"
echo "========================================"

# Check if EC2_IP is provided
if [ -z "$EC2_IP" ]; then
    echo -e "${RED}❌ Error: EC2 IP address not provided${NC}"
    echo "Usage: ./deploy.sh [EC2_IP] [KEY_FILE]"
    echo "Example: ./deploy.sh 3.25.123.45 ~/.ssh/streamsync.pem"
    exit 1
fi

# Check if KEY_FILE is provided
if [ -z "$KEY_FILE" ]; then
    echo -e "${RED}❌ Error: SSH key file not provided${NC}"
    echo "Usage: ./deploy.sh [EC2_IP] [KEY_FILE]"
    exit 1
fi

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}❌ Error: Key file not found: $KEY_FILE${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f "backend/.env" ]; then
    echo -e "${RED}❌ Error: backend/.env file not found${NC}"
    echo "Please create .env file from .env.production.example"
    exit 1
fi

echo -e "${YELLOW}📦 Building Docker image...${NC}"
cd backend
docker build -t $DOCKER_IMAGE . || {
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
}

echo -e "${YELLOW}💾 Saving Docker image...${NC}"
docker save $DOCKER_IMAGE | gzip > ${DOCKER_IMAGE}.tar.gz

echo -e "${YELLOW}📤 Uploading to EC2...${NC}"
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no ${DOCKER_IMAGE}.tar.gz ${REMOTE_USER}@${EC2_IP}:~/ || {
    echo -e "${RED}❌ Failed to upload Docker image${NC}"
    rm ${DOCKER_IMAGE}.tar.gz
    exit 1
}

scp -i "$KEY_FILE" -o StrictHostKeyChecking=no .env ${REMOTE_USER}@${EC2_IP}:~/ || {
    echo -e "${RED}❌ Failed to upload .env file${NC}"
    rm ${DOCKER_IMAGE}.tar.gz
    exit 1
}

# Clean up local tar file
rm ${DOCKER_IMAGE}.tar.gz

echo -e "${YELLOW}🔧 Deploying on EC2...${NC}"
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ${REMOTE_USER}@${EC2_IP} << 'ENDSSH'
set -e

echo "📥 Loading Docker image..."
docker load < streamsync-backend.tar.gz

echo "🛑 Stopping existing container..."
docker stop streamsync-api 2>/dev/null || true
docker rm streamsync-api 2>/dev/null || true

echo "🚀 Starting new container..."
docker run -d \
  --name streamsync-api \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  streamsync-backend

echo "⏳ Waiting for application to start..."
sleep 5

echo "📊 Container status:"
docker ps | grep streamsync-api

echo ""
echo "📋 Application logs (last 20 lines):"
docker logs --tail 20 streamsync-api

echo ""
echo "✅ Deployment complete!"
echo "🌐 API URL: http://$(curl -s ifconfig.me):3000"
echo "📖 API Docs: http://$(curl -s ifconfig.me):3000/api/docs"
echo ""
echo "To view logs: docker logs -f streamsync-api"
echo "To restart: docker restart streamsync-api"
echo "To stop: docker stop streamsync-api"

# Clean up
rm ~/streamsync-backend.tar.gz
ENDSSH

echo ""
echo -e "${GREEN}✅ Deployment successful!${NC}"
echo -e "${GREEN}🌐 Your API is now running at: http://${EC2_IP}:3000${NC}"
echo -e "${GREEN}📖 API Documentation: http://${EC2_IP}:3000/api/docs${NC}"
echo ""
echo -e "${YELLOW}📱 Next steps:${NC}"
echo "1. Update Flutter app API base URL to: http://${EC2_IP}:3000"
echo "2. Test the /health endpoint: curl http://${EC2_IP}:3000/health"
echo "3. (Optional) Set up domain and SSL certificate"
echo ""
echo -e "${YELLOW}📝 To view logs:${NC}"
echo "ssh -i $KEY_FILE ${REMOTE_USER}@${EC2_IP} 'docker logs -f streamsync-api'"
