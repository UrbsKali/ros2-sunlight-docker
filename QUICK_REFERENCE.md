# Quick Reference Guide

## Initial Setup

```bash
# 1. Copy and configure environment
cp .env.example .env
nano .env  # Edit username/password

# 2. Build Docker image
docker-compose build

# 3. Start container
docker-compose up -d

# 4. Verify GPU and services
docker-compose exec ros2-sunshine nvidia-smi
docker-compose logs ros2-sunshine
```

## Common Operations

### Connect Remotely

**Using Moonlight Client:**
1. Download: https://moonlight-stream.org/
2. Add host: `<your-server-ip>:48010`
3. Login with credentials from `.env`
4. Click to stream!

### Access Container Shell

```bash
docker-compose exec ros2-sunshine bash

# Inside container:
source /opt/ros/jazzy/setup.bash
```

### Launch ROS2 Applications

```bash
# RViz (visualization)
docker-compose exec ros2-sunshine bash
source /opt/ros/jazzy/setup.bash
rviz2

# Gazebo (simulation)
gazebo

# Your custom node
ros2 run your_package your_executable
```

### Check Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f ros2-sunshine

# Last 50 lines
docker-compose logs --tail=50
```

### Monitor Performance

```bash
# See CPU, Memory, GPU usage
docker stats ros2-sunshine

# Detailed with GPU info
docker-compose exec ros2-sunshine nvidia-smi mps.server.list
```

## Troubleshooting

### GPU Not Working?

```bash
# Check GPU detection
docker-compose exec ros2-sunshine nvidia-smi

# Verify Docker runtime
docker info | grep nvidia

# Check host GPU
lspci | grep NVIDIA
```

### No Display/X11 Issues?

```bash
# Check display in container
docker-compose exec ros2-sunshine echo $DISPLAY

# Try xvfb (virtual display)
docker-compose exec ros2-sunshine ps aux | grep Xvfb

# Test X11
docker-compose exec ros2-sunshine xeyes
# Should appear in Moonlight stream
```

### Connection Issues?

```bash
# Check ports
netstat -tlnp | grep -E "47989|47990|48010"

# Test locally in container
docker-compose exec ros2-sunshine curl -k https://localhost:48010

# View Sunshine logs
docker-compose logs ros2-sunshine | grep -i sunshine
```

### Out of Memory?

```bash
# Check memory usage
docker stats

# Increase limit in docker-compose.yml:
# mem_limit: 16g

# Restart container
docker-compose restart
```

## Maintenance

### Update ROS2 Packages

```bash
docker-compose exec ros2-sunshine bash

apt update
apt upgrade
rosdep update

colcon build
```

### Backup User Workspace

```bash
make backup-workspace
# Creates: backups/ros2_ws_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Restore from Backup

```bash
make restore-workspace
```

### Clean Everything

```bash
# Stop and remove container, volumes, image
make clean

# Or manually:
docker-compose down -v
docker rmi ros2-jazzy-sunshine:latest
```

## Environment Variables

Edit `.env` file to customize:

| Variable | Purpose | Default |
|----------|---------|---------|
| `DISPLAY` | X11 display | `:0` |
| `ROS_DOMAIN_ID` | ROS2 domain | `0` |
| `SUNSHINE_USERNAME` | Login user | `admin` |
| `SUNSHINE_PASSWORD` | Login password | `change_me` |
| `NVIDIA_VISIBLE_DEVICES` | GPU selection | `all` |
| `SUNSHINE_BITRATE` | Streaming bitrate (kbps) | `20000` |
| `SUNSHINE_FRAMERATE` | Streaming FPS | `60` |
| `SUNSHINE_QUALITY` | Quality preset | `high` |

## Make Commands

```bash
make help          # Show all commands
make build         # Build image
make up            # Start container
make down          # Stop container
make logs          # View logs
make shell         # Enter bash
make restart       # Restart container
make status        # Show status
make gpu-check     # Verify GPU
make clean         # Remove all
```

## Docker Compose Commands

```bash
docker-compose build           # Build image
docker-compose up -d           # Start in background
docker-compose down            # Stop and remove
docker-compose logs -f         # Follow logs
docker-compose exec [service] bash  # Enter shell
docker-compose ps              # Show status
docker-compose restart [service]   # Restart
docker-compose rm              # Remove stopped containers
```

## Network/Ports
```bash
47989/tcp   - Sunshine control (TCP)
47989/udp   - Sunshine control (UDP)
47990/tcp   - Sunshine video stream (TCP)
47990/udp   - Sunshine video stream (UDP)
48010/tcp   - Moonlight websocket (TCP)
48010/udp   - Moonlight websocket (UDP)
```

## Profile for Remote Management

### SSH Access to Server
```bash
ssh user@your-server-ip

# Then manage Docker
docker-compose logs
docker-compose restart
```

### VPN for Secure Remote Connection
For internet access, use VPN or SSH tunneling:
```bash
# Local machine
ssh -L 48010:localhost:48010 user@your-server-ip

# Then connect Moonlight to localhost:48010
```

## Performance Tips

### High-Performance Streaming (Full HD 60fps)
```bash
SUNSHINE_BITRATE=25000      # 25 Mbps
SUNSHINE_FRAMERATE=60
SUNSHINE_QUALITY=high
SUNSHINE_RESOLUTION_WIDTH=1920
SUNSHINE_RESOLUTION_HEIGHT=1080
```

### 4K Streaming (needs more bandwidth)
```bash
SUNSHINE_BITRATE=50000      # 50 Mbps
SUNSHINE_FRAMERATE=60
SUNSHINE_QUALITY=high
SUNSHINE_RESOLUTION_WIDTH=3840
SUNSHINE_RESOLUTION_HEIGHT=2160
```

### Low-Bandwidth Streaming
```bash
SUNSHINE_BITRATE=8000       # 8 Mbps
SUNSHINE_FRAMERATE=30
SUNSHINE_QUALITY=low
SUNSHINE_RESOLUTION_WIDTH=1280
SUNSHINE_RESOLUTION_HEIGHT=720
```

## Security Reminders

⚠️ **IMPORTANT:**
- Change default password immediately
- Don't expose to internet without VPN/firewall
- Use firewall rules to restrict access
- Regenerate Sunshine certificates for production
- Keep NVIDIA drivers updated
- Use strong passwords (20+ characters)

---

For more help, see: README.md
