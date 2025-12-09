# SCION Experiments Guide

Hands-on experiments to explore SCION's capabilities.

## Experiment 1: Path Discovery

**Goal**: Understand how SCION discovers multiple paths.

### Steps

```bash
# 1. Start the network
make up && sleep 20

# 2. View paths from AS111 to AS211
make paths
```

### Expected Output

```
╔══════════════════════════════════════════════════════════════╗
║           SCION Path Discovery                               ║
╚══════════════════════════════════════════════════════════════╝

  Source:      1-ff00:0:111
  Destination: 2-ff00:0:211

[0] Hops: [1-ff00:0:111#2 > 2-ff00:0:211#2] MTU: 1472 Latency: ~1ms
    (Direct peer link)

[1] Hops: [1-ff00:0:111#1 > 1-ff00:0:110#2 > 1-ff00:0:110#1 > 
          2-ff00:0:210#1 > 2-ff00:0:210#2 > 2-ff00:0:211#1]
    MTU: 1472 Latency: ~3ms
    (Via core ASes)
```

### Analysis
- Path 0 is shorter (direct peer link)
- Path 1 traverses both ISD cores
- Both paths are valid and usable

---

## Experiment 2: Link Failure & Failover

**Goal**: Observe how SCION handles link failures.

### Steps

```bash
# 1. Verify current paths
make paths

# 2. Break the core link (stop AS110's router)
make break-link ROUTER=router-110

# 3. Wait for path updates (~10 seconds)
sleep 10

# 4. Check available paths again
make paths
```

### Expected Result
- Before: 2+ paths available
- After: Only the PEER path remains (111 → 211 direct)
- The core path through AS110 is no longer valid

### Restore
```bash
make restore-link ROUTER=router-110
sleep 20
make paths  # Core path should return
```

---

## Experiment 3: Latency Comparison

**Goal**: Compare latency across different paths.

### Steps
```bash
# Measure latency on all paths
make measure
```

### Analysis
- Direct peer link: ~1-2ms (fewer hops)
- Core path: ~3-5ms (more hops)
- Latency difference is small in Docker (same host)
- In real networks, geographic distance matters more

---

## Experiment 4: Interactive Path Selection

**Goal**: Manually select a path and observe PCFS.

### Steps
```bash
make interactive
```

### Walk-through
1. Script shows all available paths
2. You select a path by index (0, 1, ...)
3. SCMP echo requests are sent over that specific path
4. Observe: the path you chose is embedded in every packet

---

## Experiment 5: Multi-Path Communication

**Goal**: Demonstrate using multiple paths simultaneously.

### Steps

Open two terminal windows:

**Terminal 1** (via core path):
```bash
make shell-111
# Inside container:
scion ping 2-ff00:0:211 -c 50
```

**Terminal 2** (observe traffic):
```bash
docker logs -f scion-router-110
# You should see packets being forwarded
```

### Advanced: Split Traffic
A real SCION application could:
1. Discover all paths via daemon
2. Measure latency on each
3. Distribute traffic based on capacity
4. Failover when a path breaks

---

## Experiment 6: Topology Modification

**Goal**: Add a new AS to the network.

### Steps

1. Edit `topology/topology.topo`:
```yaml
ASes:
  # Add new AS in ISD 1
  "1-ff00:0:112":
    cert_issuer: 1-ff00:0:110
    mtu: 1472

links:
  # Connect to existing leaf
  - {a: "1-ff00:0:111#3", b: "1-ff00:0:112#1", linkAtoB: PEER}
```

2. Update `docker-compose.yml` (add services for AS112)

3. Update `scripts/setup.sh` (generate AS112 configs)

4. Regenerate and restart:
```bash
make clean
make setup
make up
```

---

## Experiment 7: Traffic Analysis

**Goal**: Observe SCION packet structure.

### Steps

```bash
# 1. Shell into a router container
docker exec -it scion-router-111 /bin/bash

# 2. Capture packets (if tcpdump is available)
tcpdump -i any -n port 50001 or port 50002

# 3. In another terminal, generate traffic
make ping
```

### Observation
SCION packets contain:
- Source/destination addresses with AS identifiers
- Complete path in the header
- Hop-by-hop forwarding information

---

## Experiment Summary

| # | Experiment | SCION Concept |
|---|------------|---------------|
| 1 | Path Discovery | Beaconing, Path Service |
| 2 | Link Failure | Isolation, Failover |
| 3 | Latency Comparison | Path Metrics |
| 4 | Interactive Selection | PCFS, Sender Control |
| 5 | Multi-Path | Path Diversity |
| 6 | Topology Modification | AS Configuration |
| 7 | Traffic Analysis | Packet Structure |

---

## Troubleshooting

**No paths available?**
```bash
# Check control service logs
docker logs scion-cs-111

# Ensure all services are running
make status
```

**Ping fails?**
```bash
# Verify daemon is reachable
docker exec scion-host-111 scion showpaths 2-ff00:0:211 --no-probe
```

**Services not starting?**
```bash
# Check for config errors
docker compose logs | grep -i error
```
