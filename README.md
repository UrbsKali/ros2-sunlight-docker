# ROS2 Jazzy + Sunshine Server Docker Setup

This Docker configuration runs **ROS2 Jazzy** with **Sunshine** streaming server for remote access, including **Gazebo** and **RViz** GUI support via GPU streaming. Optimized for NVIDIA GTX 1080 Ti with GPU passthrough.

## Prerequisites

- **Linux Server** with Docker and Docker Compose installed
- **NVIDIA GPU**: GTX 1080 Ti (or compatible NVIDIA GPU)
- **NVIDIA Docker Runtime**: Install from https://github.com/NVIDIA/nvidia-docker
- **X11 Server**: If running on headless system, install Xvfb or similar
- **At least 8GB RAM** (16GB+ recommended for Gazebo simulations)

### NVIDIA Docker Runtime Installation

```bash
# Ubuntu/Debian
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Check GPU Access

```bash
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.2.2-runtime-ubuntu22.04 nvidia-smi
```

## Quick Start

### 1. Clone/Setup
```bash
cd /path/to/ros2-sunlight-docker
cp .env.example .env
```

### 2. Configure Credentials
Edit `.env` file and **change the Sunshine credentials**:
```bash
# Edit .env
SUNSHINE_USERNAME=your_username
SUNSHINE_PASSWORD=your_secure_password
```

### 3. Build and Run
```bash
# Build the Docker image
docker-compose build

# Start the container
docker-compose up -d

# View logs
docker-compose logs -f
```

### 4. Access Services

**Moonlight Remote Desktop** (stream VS Code, RViz, Gazebo):
- Download: https://moonlight-stream.org/
- Add host: `<server-ip>:48010`
- Credentials: from `.env` file

**Launch VS Code** (inside container via Moonlight):
```bash
docker-compose exec ros2-sunshine bash
code &
```
VS Code will appear in your Moonlight stream window.

## Architecture

### Services Running in Container

1. **Sunshine Server** - Remote streaming via Moonlight protocol
2. **Xvfb** - Virtual X11 display (headless X server)
3. **ROS2 Jazzy** - ROS distribution with Gazebo and RViz pre-installed
4. **Supervisord** - Process supervisor to manage services

### Port Mapping

| Port | Protocol | Purpose |
|------|----------|---------|
| 47989 | TCP/UDP | Sunshine control protocol |
| 47990 | TCP/UDP | Sunshine video stream |
| 48010 | TCP/UDP | Sunshine websocket (Moonlight connections) |

## GPU Configuration

### GTX 1080 Ti Setup

The Dockerfile automatically detects and uses the NVIDIA GPU:

- **CUDA Version**: 13.2.0 (compatible with GTX 1080 Ti)
- **Encoder**: NVENC (hardware video encoding)
- **Driver**: Uses host's NVIDIA drivers (mounted via Docker runtime)

Check GPU in container:
```bash
docker-compose exec ros2-sunshine nvidia-smi
```

### GPU Passthrough Verification

```bash
# On host
lspci | grep NVIDIA

# In container
docker-compose exec ros2-sunshine lspci | grep NVIDIA
```

## Volume Management

### ROS2 Workspace Persistence

Your ROS2 workspace is stored in a Docker volume for persistence:

```bash
# View volume location
docker volume inspect ros2-sunlight-docker_ros2_workspace

# To persist user code, mount local directory instead:
# Edit docker-compose.yml and modify ros2_workspace volume:
# volumes:
#   - ./ros2_ws:/home/ros/ros2_ws:rw
```

### Creating Your Own ROS2 Packages

```bash
# Enter the container
docker-compose exec ros2-sunshine bash

# Inside container:
cd /home/ros/ros2_ws/src

# Create your package
ros2 pkg create my_package --build-type ament_cmake

# Build workspace
cd ..
colcon build

# Source and run
source install/setup.bash
ros2 launch my_package launch_file.py
```

## X11 Display Configuration

### For Systems with Display Server

If your Linux server has an X11 display server:

```bash
# Allow container to access X11
xhost +local:

# Set DISPLAY variable
export DISPLAY=:0

# Run with docker-compose (already configured)
docker-compose up
```

### For Headless Systems

The container includes **Xvfb** (virtual X11 server) which is auto-started:

```bash
# The display will be available at :0 in container
# Sunshine will stream the virtual X11 display via Moonlight
```

### Verify X11 Connection

```bash
# Inside container
docker-compose exec ros2-sunshine bash
echo $DISPLAY
xauth list
```

## RViz and Gazebo via Remote Streaming

### Launch Gazebo

```bash
docker-compose exec ros2-sunshine bash
source /opt/ros/jazzy/setup.bash

# Start an empty Gazebo world
gazebo

# Or with a specific world
gazebo /opt/ros/jazzy/share/gazebo_ros/worlds/empty.world
```

### Launch RViz

```bash
docker-compose exec ros2-sunshine bash
source /opt/ros/jazzy/setup.bash

# Start RViz
rviz2
```

The GUI will be streamed to your client machine via Moonlight!

## Sunshine Authentication

### Generate TLS Certificates

For secure HTTPS connections, generate certificates:

```bash
docker-compose exec ros2-sunshine bash

# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout /root/.config/sunshine/key.pem \
  -out /root/.config/sunshine/cert.pem -days 365 -nodes
```

### Update Credentials

Edit `sunshine.conf`:
```ini
username = your_username
password = your_password
```

Restart the container:
```bash
docker-compose restart ros2-sunshine
```

## Environment Variables

All variables defined in `.env` file:

- `DISPLAY` - X11 display to stream
- `ROS_DISTRO` - ROS2 distribution (jazzy)
- `ROS_DOMAIN_ID` - ROS2 domain ID for multi-robot systems
- `SUNSHINE_USERNAME` - Moonlight authentication username
- `SUNSHINE_PASSWORD` - Moonlight authentication password
- `NVIDIA_VISIBLE_DEVICES` - GPU selection
- `SUNSHINE_BITRATE` - Video stream bitrate
- `SUNSHINE_FRAMERATE` - Video stream frame rate
- `SUNSHINE_QUALITY` - Streaming quality preset

## Troubleshooting

### GPU Not Detected

```bash
# Check host GPU
lspci | grep NVIDIA

# Check nvidia-docker installation
docker run --rm --runtime=nvidia nvidia/cuda:12.2.2-runtime-ubuntu22.04 nvidia-smi

# If command not found, reinstall nvidia-docker2
```

### X11 Connection Failed

```bash
# Check X11 socket on host
ls -la /tmp/.X11-unix/

# Allow access from container
xhost +local:

# Or if using headless, Xvfb should auto-start
docker-compose logs ros2-sunshine | grep Xvfb
```

### Sunshine Connection Issues

```bash
# Check Sunshine logs
docker-compose logs -f ros2-sunshine

# Verify port binding
netstat -tlnp | grep sunshine

# Test connection locally
curl -u admin:change_me https://localhost:48010 -k
```

### RViz/Gazebo Not Displaying

```bash
# Verify DISPLAY variable
docker-compose exec ros2-sunshine echo $DISPLAY

# Check X11 forwarding
docker-compose exec ros2-sunshine xauth list

# Test X11 display
docker-compose exec ros2-sunshine xeyes &
# Should appear in Moonlight stream
```

### Out of Memory

Gazebo and RViz are memory-intensive:

```bash
# Check container memory usage
docker stats ros2-sunshine

# Increase Docker memory limit in docker-compose.yml:
# mem_limit: 16g
```

## Advanced Configuration

### Custom ROS2 Launch Files

Create a `ros2_launch.py` file in your workspace for auto-startup:

```bash
mkdir -p /path/to/ros2_ws/src
cat > ros2_launch.py << 'EOF'
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='your_package',
            executable='your_executable',
            output='screen'
        ),
    ])
EOF
```

Enable in supervisord.conf by uncommenting `[program:ros2-launch]`

### Network Configuration

For multi-machine ROS2:

```bash
# In .env, configure ROS2 middleware:
ROS_DOMAIN_ID=0
ROS_MIDDLEWARE_IMPLEMENTATION=rmw_cyclonedds_cpp
```

### Performance Tuning for GTX 1080 Ti

For 4K streaming @ 60fps:

```ini
; In sunshine.conf
bitrate = 50000  ; 50 Mbps
framerate = 60
quality = high
encoder = nvenc

; In .env
SUNSHINE_RESOLUTION_WIDTH=3840
SUNSHINE_RESOLUTION_HEIGHT=2160
```

## Maintenance

### Update ROS2 Packages

```bash
docker-compose exec ros2-sunshine bash
apt update && apt upgrade
rosdep update
colcon build --packages-select <package_name>
```

### Backup Workspace

```bash
# Backup workspace volume
docker run --rm -v ros2-sunlight-docker_ros2_workspace:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/ros2_ws_backup.tar.gz -C /data .
```

### Clean Up

```bash
# Stop and remove containers
docker-compose down

# Remove image
docker rmi ros2-jazzy-sunshine:latest

# Remove volumes
docker volume rm ros2-sunlight-docker_ros2_workspace ros2-sunlight-docker_sunshine_config
```

## Security Considerations

⚠️ **IMPORTANT**: This setup is for internal LAN use. For internet exposure:

1. Use strong passwords (`.env` file)
2. Generate TLS certificates (see above)
3. Use VPN or SSH tunneling for remote connections
4. Keep NVIDIA drivers and OS updated
5. Restrict Sunshine container network access

## References

- [ROS2 Jazzy Documentation](https://docs.ros.org/en/jazzy/)
- [Sunshine Project](https://github.com/LizardByte/Sunshine)
- [Moonlight Client](https://moonlight-stream.org/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)
- [NVIDIA CUDA Compute Capability](https://developer.nvidia.com/cuda-gpus)

## Support

For issues with:
- **ROS2**: https://discourse.ros.org/
- **Sunshine**: https://github.com/LizardByte/Sunshine/issues
- **GPU**: Check NVIDIA driver compatibility and CUDA documentation

---

**Last Updated**: 2026-04-08  
**Image**: ROS2 Jazzy + Sunshine (GPU-enabled)  
**Target Hardware**: NVIDIA GTX 1080 Ti
