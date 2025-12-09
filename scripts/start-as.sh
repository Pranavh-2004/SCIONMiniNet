#!/bin/bash
# Start all SCION services for an AS
# Usage: start-as.sh <AS_NUMBER>

AS_NUM=$1
CONFIG_DIR="/etc/scion"

echo "🚀 Starting SCION services for AS $AS_NUM..."

# Kill any existing SCION processes
pkill -9 scion-dispatcher scion-control-service scion-border-router sciond 2>/dev/null || true
sleep 1

# Create required directories
mkdir -p /var/lib/scion /run/shm/dispatcher /etc/scion/crypto/as

# Copy certificate chain to crypto/as if it exists in certs
if [ -f "$CONFIG_DIR/certs/cp-as.pem" ]; then
    cp "$CONFIG_DIR/certs/cp-as.pem" "$CONFIG_DIR/crypto/as/"
fi
if [ -f "$CONFIG_DIR/certs/cp-ca.crt" ]; then
    cp "$CONFIG_DIR/certs/cp-ca.crt" "$CONFIG_DIR/crypto/as/"
fi

# Start control service FIRST (before dispatcher to avoid port conflicts)
if [ -f "$CONFIG_DIR/cs.toml" ]; then
    echo "  Starting control service..."
    scion-control-service --config "$CONFIG_DIR/cs.toml" &
    sleep 3
fi

# Start dispatcher
echo "  Starting dispatcher..."
if [ -f "$CONFIG_DIR/dispatcher.toml" ]; then
    scion-dispatcher --config "$CONFIG_DIR/dispatcher.toml" &
    sleep 2
fi

# Start border router
if [ -f "$CONFIG_DIR/br.toml" ]; then
    echo "  Starting border router..."
    scion-border-router --config "$CONFIG_DIR/br.toml" &
    sleep 2
fi

# Start SCION daemon
if [ -f "$CONFIG_DIR/sd.toml" ]; then
    echo "  Starting SCION daemon..."
    sciond --config "$CONFIG_DIR/sd.toml" &
    sleep 2
fi

echo "✅ AS $AS_NUM services started!"
echo ""
echo "Running processes:"
ps aux | grep -E "(scion|sciond)" | grep -v grep || echo "  No SCION processes found"
echo ""
echo "Available SCION tools:"
echo "  scion showpaths <dest-AS>   - Show paths to destination"
echo "  scion ping <dest-AS>        - Ping destination"
echo "  scion traceroute <dest-AS>  - Traceroute to destination"

# Keep container running
tail -f /dev/null
