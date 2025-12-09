# SCIONMiniNet Usage Guide

A step-by-step guide to running and exploring your local SCION network.

## Prerequisites

- **Docker Desktop** (with Docker Compose v2)
- **4GB RAM** available
- **macOS/Linux** (Windows WSL2 works too)

## Quick Start

### 1. Setup the Network

```bash
# Generate all configuration files
make setup

# Start all containers
make up
```

### 2. Wait for Convergence

> **Important:** SCION needs 30-60 seconds to propagate beacons. Wait before testing!

```bash
# Wait for network to converge
sleep 45
```

### 3. Verify the Network

```bash
# Check container status
make status

# Discover paths (should show paths after convergence)
make paths
```

### 4. Test Connectivity

```bash
# SCION ping between ASes
make ping

# Or manually:
docker exec scion-as111 scion ping 1-ff00:0:110,172.20.0.10 -c 3 \
    --sciond 172.20.0.20:30255
```

---

## Command Reference

| Command | Description |
|---------|-------------|
| `make setup` | Generate SCION configs and PKI |
| `make up` | Start all containers |
| `make down` | Stop all containers |
| `make status` | Show container health |
| `make logs` | View all service logs |
| `make paths` | Discover paths from AS111 to AS211 |
| `make ping` | SCION ping test |
| `make measure` | Measure latency on all paths |
| `make clean` | Remove all generated files |
| `make visualizer` | Start the GUI visualizer |

---

## Network Details

### Topology Overview

```
ISD 1 (Academic)     ←→     ISD 2 (Commercial)
     │                           │
  AS110 (Core) ←──CORE──→ AS210 (Core)
     │                           │
  AS111 (Leaf) ←──PEER──→ AS211 (Leaf)
```

### Container IP Addresses

| AS | Container | IP Address |
|----|-----------|------------|
| 1-ff00:0:110 | scion-as110 | 172.20.0.10 |
| 1-ff00:0:111 | scion-as111 | 172.20.0.20 |
| 2-ff00:0:210 | scion-as210 | 172.20.0.30 |
| 2-ff00:0:211 | scion-as211 | 172.20.0.40 |

### SCION Daemon Addresses

Each AS runs a SCION Daemon (sciond) on port `30255`:
- AS110: `172.20.0.10:30255`
- AS111: `172.20.0.20:30255`
- AS210: `172.20.0.30:30255`
- AS211: `172.20.0.40:30255`

---

## Manual SCION Commands

From inside any container:

```bash
# Enter a container shell
docker exec -it scion-as111 bash

# Show paths to another AS
scion showpaths 2-ff00:0:210 --sciond 172.20.0.20:30255

# Ping another AS (format: ISD-AS,IP)
scion ping 2-ff00:0:210,172.20.0.30 -c 5 --sciond 172.20.0.20:30255

# Traceroute
scion traceroute 2-ff00:0:210,172.20.0.30 --sciond 172.20.0.20:30255
```

---

## Troubleshooting

### "No paths found"

**Solution:** Wait longer for beacon propagation.

```bash
sleep 60 && make paths
```

### "TRC not found" in logs

**Solution:** This is normal during startup. Services load TRCs within ~10 seconds.

### Containers not starting

```bash
# Check logs
docker compose logs | tail -50

# Restart everything
make down && make up
```

### Want more debug info

Edit `scripts/setup.sh` and change:
```bash
level = "debug"  # Currently enabled
level = "info"   # For less verbose logs
```

---

## Files Reference

| Path | Description |
|------|-------------|
| `gen/AS*/topology.json` | Network topology for each AS |
| `gen/AS*/cs.toml` | Control Service config |
| `gen/AS*/br.toml` | Border Router config |
| `gen/AS*/sd.toml` | SCION Daemon config |
| `gen/AS*/certs/` | TRC and certificate files |
| `gen/AS*/keys/` | Master keys |

---

*For more details, see [README.md](../README.md) and [docs/CONCEPTS.md](CONCEPTS.md)*
