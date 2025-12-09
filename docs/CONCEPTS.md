# SCION Concepts Deep-Dive

## What is SCION?

SCION (Scalability, Control, and Isolation on Next-generation Networks) is a clean-slate Internet architecture designed to provide route control, failure isolation, and explicit trust. Unlike BGP-based routing, SCION gives endpoints visibility and control over network paths.

## Core Concepts

### 1. Isolation Domains (ISDs)

An ISD is a trust domain—a group of ASes that agree on a trust root and governance policies.

```
┌─────────────────────────────────────────────┐
│  ISD 1 (Academic)     │  ISD 2 (Commercial) │
│                       │                     │
│  Shared trust root    │  Shared trust root  │
│  Common policies      │  Common policies    │
│  AS 110, AS 111       │  AS 210, AS 211     │
└─────────────────────────────────────────────┘
```

**Why ISDs matter:**
- Failures in one ISD don't affect others
- Trust is explicit, not globally assumed
- Policies are locally enforced

### 2. AS (Autonomous System) Hierarchy

Within an ISD, ASes form a hierarchy:

| Role | Description | Our Topology |
|------|-------------|--------------|
| **Core AS** | ISD backbone, originates beacons | AS 110, AS 210 |
| **Non-Core AS** | Connects to core or other non-core | AS 111, AS 211 |

Link types:
- **CORE**: Between core ASes (including inter-ISD)
- **PARENT/CHILD**: Provider-customer relationship
- **PEER**: Lateral connection, no hierarchy

### 3. Path Discovery (Beaconing)

SCION uses **Path-Segment Construction Beacons (PCBs)** to discover paths:

```
Core AS 110 creates beacon
       │
       ▼ Propagates down
Non-core AS 111 receives beacon
       │
       ▼ Registers path segment
Path stored in Path Service
       │
       ▼ 
Endpoint queries daemon for paths
```

Path segments are:
- **Up segments**: From local AS toward core
- **Down segments**: From core toward destination AS
- **Core segments**: Between core ASes

### 4. Packet-Carried Forwarding State (PCFS)

Unlike IP packets (which only carry destination address), SCION packets carry the **complete path**:

```
┌─────────────────────────────────────────────────────┐
│ SCION Packet Header                                 │
├─────────────────────────────────────────────────────┤
│ Source:      1-ff00:0:111,172.20.0.23               │
│ Destination: 2-ff00:0:211,172.20.0.43               │
│ Path:        [111#2 > 211#2]                        │
│              ↑ Complete forwarding instructions     │
└─────────────────────────────────────────────────────┘
```

**Benefits:**
- Routers don't need routing tables—just follow the path
- Sender chooses the path based on their needs
- Path changes don't require router state updates

### 5. Path Selection

Endpoints (not routers) select paths. Selection criteria include:

| Criteria | Example |
|----------|---------|
| **Latency** | Gaming, real-time communication |
| **Bandwidth** | Large file transfers |
| **Jurisdictions** | Data sovereignty requirements |
| **Providers** | Avoid untrusted ASes |
| **Redundancy** | Use multiple paths simultaneously |

```bash
# In our topology, you can:
# - Choose the direct PEER path (lower latency)
# - Choose the CORE path (different trust domain)
make interactive
```

### 6. Control Plane vs Data Plane

| Plane | Components | Function |
|-------|------------|----------|
| **Control** | Control Service, Beacons | Path discovery & registration |
| **Data** | Border Router, Dispatcher | Packet forwarding |

The control plane pre-computes paths; the data plane forwards packets along those paths.

## How Our Topology Demonstrates These Concepts

```
Concept                  │ Demonstrated By
─────────────────────────┼────────────────────────────────────
Isolation Domains        │ ISD 1 vs ISD 2
AS Hierarchy             │ Core (110, 210) and Leaf (111, 211)
Path Diversity           │ Direct peer link vs core path
Beaconing               │ CS services propagate path info
Path Selection          │ `make interactive` lets you choose
PCFS                    │ Ping shows path in packet headers
```

## Further Reading

1. **SCION Book**: [scion-architecture.net/book](https://scion-architecture.net/book/)
2. **Research Paper**: "SCION: Scalability, Control, and Isolation on Next-Generation Networks"
3. **Reference Implementation**: [github.com/scionproto/scion](https://github.com/scionproto/scion)
