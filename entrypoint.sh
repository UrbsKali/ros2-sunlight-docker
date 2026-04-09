#!/bin/bash
set -e

echo "========================================="
echo "ROS2 Jazzy + Sunshine Server"
echo "========================================="

# Set environment variables
export DISPLAY="${DISPLAY:-:0}"
export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"

# Update Sunshine credentials if provided via environment
if [ ! -z "$SUNSHINE_USERNAME" ] && [ ! -z "$SUNSHINE_PASSWORD" ]; then
    echo "Setting Sunshine credentials..."
    # Sunshine configuration is handled at build time
fi

# Initialize ROS2
echo "Initializing ROS2..."
source /opt/ros/jazzy/setup.bash

# Source user workspace if it exists
if [ -f /home/ros/ros2_ws/install/setup.bash ]; then
    echo "Sourcing ROS2 workspace..."
    source /home/ros/ros2_ws/install/setup.bash
fi

# Create log directory for supervisor
mkdir -p /var/log/supervisor

# Check GPU availability
echo "Checking GPU availability..."
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected:"
    nvidia-smi -L
else
    echo "WARNING: NVIDIA GPU not detected. GPU passthrough may not be working."
fi

# Display configuration
echo "Display configuration:"
echo "DISPLAY=$DISPLAY"

# Check X11 socket
if [ ! -e /tmp/.X11-unix/0 ]; then
    echo "WARNING: X11 socket not found at /tmp/.X11-unix/0"
    echo "X11 forwarding may not work properly."
fi

# First-boot setup tasks (idempotent)
if [ -x /preinstall.sh ]; then
    /preinstall.sh
else
    echo "WARNING: /preinstall.sh is missing or not executable; skipping first-boot setup."
fi

echo "Starting Supervision..."
echo "========================================="

# Execute the command passed to the container
exec "$@"
