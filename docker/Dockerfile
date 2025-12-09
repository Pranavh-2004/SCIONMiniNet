# SCION Learning Container
# Uses amd64 packages with emulation for Apple Silicon compatibility

FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    iproute2 \
    iputils-ping \
    net-tools \
    tcpdump \
    vim \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add SCION repository (amd64 packages from ETH Zurich)
RUN echo "deb [trusted=yes] https://packages.netsec.inf.ethz.ch/debian all main" > /etc/apt/sources.list.d/scionlab.list

# Install SCION packages (correct package names)
RUN apt-get update && apt-get install -y \
    scion-control-service \
    scion-border-router \
    scion-daemon \
    scion-dispatcher \
    scion-tools \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/scion /var/lib/scion /run/shm/dispatcher

# Set working directory
WORKDIR /etc/scion

# Default command - can be overridden
CMD ["sleep", "infinity"]
