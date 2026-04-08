FROM nvidia/cuda:13.2.0-runtime-ubuntu24.04

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
    git \
    build-essential \
    cmake \
    python3-pip \
    python3-dev \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Add ROS 2 repository using modern keyring method
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && mkdir -p /usr/share/keyrings \
    && curl -sSL https://repo.ros2.org/ros.key -o /root/ros-archive-keyring.gpg \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BABE3D &>/dev/null || true \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://repo.ros2.org/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list \
    && rm -rf /var/lib/apt/lists/*

# Install ROS 2 Jazzy
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-desktop \
    ros-jazzy-gazebo-ros-pkgs \
    ros-jazzy-gazebo-ros2-control \
    ros-jazzy-rviz2 \
    ros-jazzy-geometry2 \
    ros-jazzy-tf2-tools \
    python3-rosdep \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# Install GPU utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    nvidia-utils \
    libcuda1-12-2 \
    && rm -rf /var/lib/apt/lists/*

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
    && wget -q https://github.com/LizardByte/Sunshine/releases/download/v0.23.0/sunshine-ubuntu-22.04-amd64.deb \
    && dpkg -i sunshine-ubuntu-22.04-amd64.deb \
    && rm sunshine-ubuntu-22.04-amd64.deb \
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
# Sunshine default port
EXPOSE 47989 47990 48010

# Set up display for X11
ENV DISPLAY=:0

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
