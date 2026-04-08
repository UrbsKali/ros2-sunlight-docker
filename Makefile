.PHONY: help build up down logs shell restart clean

help:
	@echo "ROS2 Sunshine Docker Management"
	@echo "================================"
	@echo "make build       - Build Docker image"
	@echo "make up          - Start container in background"
	@echo "make down        - Stop and remove container"
	@echo "make logs        - View container logs"
	@echo "make shell       - Enter container bash shell"
	@echo "make restart     - Restart container"
	@echo "make clean       - Remove containers, images, and volumes"
	@echo "make status      - Show container status"
	@echo "make gpu-check   - Verify GPU access in container"

build:
	@echo "Building Docker image..."
	docker-compose build

up:
	@echo "Starting ROS2 Sunshine container..."
	docker-compose up -d
	@echo "Container started. Waiting for Sunshine to initialize..."
	@sleep 5
	docker-compose logs ros2-sunshine | tail -20

down:
	@echo "Stopping container..."
	docker-compose down

logs:
	docker-compose logs -f ros2-sunshine

shell:
	@echo "Entering container shell..."
	docker-compose exec ros2-sunshine bash

restart:
	@echo "Restarting container..."
	docker-compose restart ros2-sunshine

status:
	docker-compose ps
	@echo ""
	docker stats --no-stream ros2-sunshine 2>/dev/null || echo "Container not running"

gpu-check:
	@echo "Checking GPU in container..."
	docker-compose exec ros2-sunshine nvidia-smi

clean:
	@echo "WARNING: This will remove all containers, images, and volumes!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		docker rmi ros2-jazzy-sunshine:latest; \
		echo "Cleanup complete"; \
	else \
		echo "Cleanup cancelled"; \
	fi

backup-workspace:
	@echo "Backing up ROS2 workspace..."
	mkdir -p backups
	docker run --rm -v ros2-sunlight-docker_ros2_workspace:/data \
		-v $$(pwd)/backups:/backup \
		alpine tar czf /backup/ros2_ws_backup_$$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
	@echo "Backup complete in backups/"

restore-workspace:
	@echo "Restoring ROS2 workspace..."
	@ls -1t backups/ros2_ws_backup_*.tar.gz | head -1 | xargs -I {} \
		docker run --rm -v ros2-sunlight-docker_ros2_workspace:/data \
		-v $$(pwd)/{}:/backup/restore.tar.gz \
		alpine tar xzf /backup/restore.tar.gz -C /data
	@echo "Restore complete"

test-connection:
	@echo "Testing Sunshine connection..."
	@echo "Testing SSL connection to Sunshine..."
	docker-compose exec ros2-sunshine curl -u admin:change_me https://localhost:48010 -k 2>/dev/null || echo "Connection test (accept SSL error if redirect)"

version:
	@echo "Checking component versions..."
	@echo "ROS2: jazzy"
	@echo "CUDA: 12.2.2"
	docker-compose exec ros2-sunshine dpkg -l | grep -E "sunshine|ros-jazzy|gazebo|rviz"

.DEFAULT_GOAL := help
