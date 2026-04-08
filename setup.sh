#!/bin/bash

# ROS2 Sunshine Docker Setup Script
# This script helps configure the Docker environment

set -e

echo "========================================"
echo "ROS2 Jazzy + Sunshine Docker Setup"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker not found${NC}"
        echo "Install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker found: $(docker --version)${NC}"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}✗ Docker Compose not found${NC}"
        echo "Install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker Compose found: $(docker-compose --version)${NC}"
    
    # Check NVIDIA GPU access
    if ! docker run --rm --gpus all nvidia/cuda:12.2.2-runtime-ubuntu22.04 nvidia-smi &>/dev/null; then
        echo -e "${RED}✗ NVIDIA GPU access is not configured${NC}"
        echo "Install and configure the NVIDIA Container Toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"
        exit 1
    fi
    echo -e "${GREEN}✓ NVIDIA GPU access configured${NC}"
    
    # Check GPU
    echo ""
    echo "GPU Detected:"
    docker run --rm --gpus all nvidia/cuda:12.2.2-runtime-ubuntu22.04 nvidia-smi -L
    echo ""
}

# Configure environment
configure_env() {
    echo "Configuring environment variables..."
    
    if [ ! -f .env ]; then
        echo "Creating .env from .env.example..."
        cp .env.example .env
        echo -e "${GREEN}✓ .env created${NC}"
    else
        echo -e "${YELLOW}⚠ .env already exists, skipping${NC}"
    fi
    
    # Ask for Sunshine credentials
    read -p "Enter Sunshine username [admin]: " username
    username=${username:-admin}
    
    read -sp "Enter Sunshine password (or press Enter for 'change_me'): " password
    echo ""
    password=${password:-change_me}
    
    # Update .env
    sed -i.bak "s/^SUNSHINE_USERNAME=.*/SUNSHINE_USERNAME=$username/" .env
    sed -i.bak "s/^SUNSHINE_PASSWORD=.*/SUNSHINE_PASSWORD=$password/" .env
    
    echo -e "${GREEN}✓ Credentials configured${NC}"
    echo ""
}

# Display configuration
display_config() {
    echo "Current Configuration:"
    echo "====================="
    grep -E "^[A-Z]" .env | grep -v "^#"
    echo ""
}

# Build image
build_image() {
    echo "Building Docker image..."
    echo "This may take 5-10 minutes on first build..."
    echo ""
    
    if docker-compose build; then
        echo -e "${GREEN}✓ Image built successfully${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
    echo ""
}

# Start container
start_container() {
    read -p "Start container now? (y/n) [y]: " start
    start=${start:-y}
    
    if [[ $start == "y" || $start == "Y" ]]; then
        echo "Starting container..."
        docker-compose up -d
        
        echo "Waiting for services to initialize..."
        sleep 3
        
        echo ""
        echo -e "${GREEN}Container Status:${NC}"
        docker-compose ps
        
        echo ""
        echo "Recent logs:"
        docker-compose logs --tail=20 ros2-sunshine
        
        echo ""
        echo -e "${GREEN}✓ Container started${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Wait 10-15 seconds for Sunshine to fully initialize"
        echo "2. On your client machine, download Moonlight: https://moonlight-stream.org/"
        echo "3. Add host: $(hostname -I | awk '{print $1}'):48010"
        echo "4. Login with credentials: $username / ****"
        echo "5. Click to stream!"
        echo ""
        echo "To view logs: docker-compose logs -f"
        echo "To enter shell: docker-compose exec ros2-sunshine bash"
        echo "To stop: docker-compose down"
    fi
}

# Main execution
main() {
    # Change to script directory
    cd "$(dirname "$0")"
    
    check_prerequisites
    echo ""
    
    configure_env
    display_config
    
    # Ask if user wants to build and start
    read -p "Proceed with building Docker image? (y/n) [y]: " proceed
    proceed=${proceed:-y}
    
    if [[ $proceed == "y" || $proceed == "Y" ]]; then
        build_image
        start_container
    else
        echo "Setup cancelled. To continue later, run:"
        echo "  docker-compose build"
        echo "  docker-compose up -d"
    fi
    
    echo "Setup complete!"
}

main "$@"
