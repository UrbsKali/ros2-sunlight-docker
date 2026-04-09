FROM nvidia/cuda:13.0.0-runtime-ubuntu24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=jazzy \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility

# Install basic dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    wget \
    micro \
    btop \
    git \
    build-essential \
    cmake \
    python3-pip \
    python3-dev \
    supervisor \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Add ROS 2 repository using official ROS2 setup script
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    lsb-release \
    gnupg \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && rm -rf /var/lib/apt/lists/*

# Install ROS 2 Jazzy
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-desktop \
    ros-jazzy-ros-gz \
    ros-jazzy-gz-ros2-control \
    ros-jazzy-rviz2 \
    ros-jazzy-geometry2 \
    ros-jazzy-tf2-tools \
    python3-rosdep \
    python3-venv \
    python3-pip \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# GPU driver libraries are provided by the NVIDIA Container Toolkit at runtime.

# Install Sunshine (streaming server)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev \
    libx11-dev \
    libxfixes-dev \
    libxrandr-dev \
    libxtst-dev \
    libevdev-dev \
    libopus-dev \
    libvdpau-dev \
    libva-dev \
    libpulse-dev \
    libcap-dev \
    x11-utils \
    xauth \
    && rm -rf /var/lib/apt/lists/*

# Install Sunshine from GitHub releases
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    pkg-config \
    miniupnpc \
    libayatana-appindicator3-1 \
    libnotify4 \
    && wget -q https://github.com/LizardByte/Sunshine/releases/download/v2025.924.154138/sunshine-ubuntu-24.04-amd64.deb \
    && apt-get install -y --no-install-recommends ./sunshine-ubuntu-24.04-amd64.deb \
    && rm sunshine-ubuntu-24.04-amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Install full VS Code (accessed via X11 display)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    libxss1 \
    libxkbfile1 \
    && wget -q https://go.microsoft.com/fwlink/?LinkID=760868 -O /tmp/code.deb \
    && apt-get install -y --no-install-recommends /tmp/code.deb \
    && rm /tmp/code.deb \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init && rosdep update

# Create ROS2 workspace directory
RUN mkdir -p /home/ros/ros2_ws/src
WORKDIR /home/ros/ros2_ws

# Source ROS2 setup in bashrc
RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc \
    && echo "source /home/ros/ros2_ws/install/setup.bash 2>/dev/null || true" >> /root/.bashrc

# Create supervisor configuration directory
RUN mkdir -p /etc/supervisor/conf.d

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create Sunshine config directory
RUN mkdir -p /root/.config/sunshine
COPY sunshine.conf /root/.config/sunshine/sunshine.conf

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
# Sunshine ports
EXPOSE 47989 47990 48010

# Set up display for X11
ENV DISPLAY=:0

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
