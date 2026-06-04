# L2 EVPN Containerlab

A containerlab project demonstrating Layer 2 EVPN VxLAN with Arista cEOS.

Two hosts communicate across a leaf-spine fabric using EVPN for MAC learning and VxLAN for data-plane encapsulation.

## Topology

```
                          +-----------+
                          |   SPINE   |
                          | 10.0.0.1  |
                          +--Et1-Et2--+
                            /        \
                           /          \
                     +----Et2---+ +---Et2----+
  +-------+   eth1   |  LEAF1   | |  LEAF2   |   eth1   +-------+
  | HOST1 |----------Et1        | |        Et1----------| HOST2 |
  +-------+          | 10.0.0.11| | 10.0.0.12|          +-------+
 192.168.10.1        +----------+ +----------+        192.168.10.2
                       VTEP          VTEP
                     VNI 10010     VNI 10010
```

## Design

| Component | Detail |
|-----------|--------|
| Underlay routing | OSPF area 0 |
| Overlay routing | iBGP EVPN (AS 65000) |
| Route reflector | Spine |
| VxLAN VNI | 10010 (VLAN 10) |
| VTEP source | Loopback0 on each leaf |
| Host image | ghcr.io/hellt/network-multitool |
| Switch image | cEOS-lab (Arista) |

## IP Addressing

| Device | Interface | IP Address | Description |
|--------|-----------|-----------|-------------|
| Spine | Loopback0 | 10.0.0.1/32 | Router ID |
| Spine | Et1 | 10.0.1.1/30 | To Leaf1 |
| Spine | Et2 | 10.0.2.1/30 | To Leaf2 |
| Leaf1 | Loopback0 | 10.0.0.11/32 | Router ID / VTEP |
| Leaf1 | Et2 | 10.0.1.2/30 | To Spine |
| Leaf1 | Et1 | switchport | To Host1 (VLAN 10) |
| Leaf2 | Loopback0 | 10.0.0.12/32 | Router ID / VTEP |
| Leaf2 | Et2 | 10.0.2.2/30 | To Spine |
| Leaf2 | Et1 | switchport | To Host2 (VLAN 10) |
| Host1 | eth1 | 192.168.10.1/24 | Client |
| Host2 | eth1 | 192.168.10.2/24 | Client |

## Management Access

| Node | Container Name | Mgmt IP | Access |
|------|---------------|---------|--------|
| Spine | clab-l2evpn-spine | 172.20.20.10 | `docker exec -it clab-l2evpn-spine Cli` |
| Leaf1 | clab-l2evpn-leaf1 | 172.20.20.11 | `docker exec -it clab-l2evpn-leaf1 Cli` |
| Leaf2 | clab-l2evpn-leaf2 | 172.20.20.12 | `docker exec -it clab-l2evpn-leaf2 Cli` |
| Host1 | clab-l2evpn-host1 | 172.20.20.21 | `docker exec -it clab-l2evpn-host1 bash` |
| Host2 | clab-l2evpn-host2 | 172.20.20.22 | `docker exec -it clab-l2evpn-host2 bash` |

## Quick Start

### Prerequisites
- Docker CE installed
- [Containerlab](https://containerlab.dev) installed
- cEOS-lab image tarball (`cEOS-lab.tar.xz`)

See [cEOS-Containerlab-Setup-Guide.md](cEOS-Containerlab-Setup-Guide.md) for detailed install steps.

### 1. Import cEOS Image
```bash
./scripts/import-image.sh /path/to/cEOS-lab.tar.xz
```

### 2. Deploy the Lab
```bash
./scripts/deploy.sh
```

### 3. Verify
```bash
# Check OSPF neighbors on leaf1
docker exec clab-l2evpn-leaf1 Cli -p 15 -c "show ip ospf neighbor"

# Check BGP EVPN on leaf1
docker exec clab-l2evpn-leaf1 Cli -p 15 -c "show bgp evpn summary"

# Check VxLAN
docker exec clab-l2evpn-leaf1 Cli -p 15 -c "show vxlan vtep"

# Ping host2 from host1
docker exec clab-l2evpn-host1 ping -c 4 192.168.10.2
```

### 4. Destroy the Lab
```bash
./scripts/destroy.sh
```

## Repository Structure

```
L2-EVPN-Lab/
├── README.md                           # This file
├── cEOS-Containerlab-Setup-Guide.md    # cEOS setup reference
├── topo.yml                            # Containerlab topology
├── configs/
│   ├── spine.cfg                       # Spine: OSPF + BGP EVPN RR
│   ├── leaf1.cfg                       # Leaf1: OSPF + BGP EVPN + VxLAN
│   └── leaf2.cfg                       # Leaf2: OSPF + BGP EVPN + VxLAN
└── scripts/
    ├── import-image.sh                 # Import cEOS rootfs into Docker
    ├── deploy.sh                       # Deploy the lab
    └── destroy.sh                      # Destroy the lab
```

## Pushing to GitHub

```bash
# Create a repo on github.com, then:
git remote add origin https://github.com/<your-username>/L2-EVPN-Lab.git
git branch -M main
git push -u origin main
```
