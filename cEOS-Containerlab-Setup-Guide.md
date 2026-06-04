# cEOS Containerlab Setup Guide

## Prerequisites

- AlmaLinux 9.x (or RHEL-based distro) VM with 30GB+ RAM and 64GB+ disk
- Docker CE installed and running
- Containerlab installed
- cEOS-lab rootfs tarball (`cEOS-lab.tar.xz`)

---

## Step 1: Install Docker CE

```bash
# Remove conflicting packages
dnf remove -y docker docker-client docker-client-latest docker-common \
  docker-latest docker-latest-logrotate docker-logrotate docker-engine \
  podman runc

# Install prerequisites
dnf install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Verify
docker --version
```

## Step 2: Install Containerlab

```bash
curl -sL https://containerlab.dev/setup | bash -s -- all

# Verify
clab version
```

## Step 3: Import the cEOS-lab Image

> **IMPORTANT:** The `cEOS-lab.tar.xz` is a raw rootfs tarball, NOT a `docker save` archive.
> You MUST use `docker import` (not `docker image load`).
> You MUST set the correct `CMD` and environment variables during import.

```bash
docker import cEOS-lab.tar.xz ceos:latest \
  --change 'CMD ["/sbin/init"]' \
  --change 'ENV INTFTYPE=eth' \
  --change 'ENV ETBA=1' \
  --change 'ENV SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1' \
  --change 'ENV CEOS=1' \
  --change 'ENV EOS_PLATFORM=ceoslab' \
  --change 'ENV container=docker'
```

### Common Mistakes to Avoid

| Mistake | Error You'll See | Why |
|---------|-----------------|-----|
| Using `docker image load` | `open .deltas/json: no such file or directory` | The tarball is a rootfs, not a Docker save archive |
| Setting `ENTRYPOINT ["bash"]` with `CMD ["/sbin/init"]` | `/usr/bin/bash: /usr/bin/bash: cannot execute binary file` | bash tries to execute itself as a script |
| Using `docker import` with no `--change` flags | Containers start but no EOS interfaces appear | Missing env vars (`CEOS`, `EOS_PLATFORM`, `INTFTYPE`, etc.) |

### Verify the Image

```bash
docker images
# Expected output:
# REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
# ceos         latest    <id>           x seconds ago    ~2.6GB
```

## Step 4: Create the Topology File

Create a file named `topo.yml`:

```yaml
name: ceos-lab
topology:
  nodes:
    ceos1:
      kind: ceos
      image: ceos:latest
    ceos2:
      kind: ceos
      image: ceos:latest
  links:
    - endpoints: ["ceos1:eth1", "ceos2:eth1"]
    - endpoints: ["ceos1:eth2", "ceos2:eth2"]
    - endpoints: ["ceos1:eth3", "ceos2:eth3"]
    - endpoints: ["ceos1:eth4", "ceos2:eth4"]
    - endpoints: ["ceos1:eth5", "ceos2:eth5"]
```

> **Note:** In the topology file, interfaces are named `ethN`.
> Inside EOS, they appear as `EtN` (Ethernet1, Ethernet2, etc.).

## Step 5: Deploy the Lab

```bash
clab deploy --topo topo.yml
```

### Expected Output

```
INFO Containerlab started version=0.76.0
INFO Parsing & checking topology file=topo.yml
INFO Creating docker network name=clab ...
INFO Creating container name=ceos1
INFO Creating container name=ceos2
INFO Created link: ceos1:eth1 ▪┄┄▪ ceos2:eth1
INFO Created link: ceos1:eth2 ▪┄┄▪ ceos2:eth2
INFO Created link: ceos1:eth3 ▪┄┄▪ ceos2:eth3
INFO Created link: ceos1:eth4 ▪┄┄▪ ceos2:eth4
INFO Created link: ceos1:eth5 ▪┄┄▪ ceos2:eth5
INFO Running postdeploy actions for Arista cEOS 'ceos1' node
INFO Running postdeploy actions for Arista cEOS 'ceos2' node

╭─────────────────────┬─────────────┬─────────┬───────────────────╮
│         Name        │  Kind/Image │  State  │   IPv4/6 Address  │
├─────────────────────┼─────────────┼─────────┼───────────────────┤
│ clab-ceos-lab-ceos1 │ ceos:latest │ running │ 172.20.20.x       │
│ clab-ceos-lab-ceos2 │ ceos:latest │ running │ 172.20.20.x       │
╰─────────────────────┴─────────────┴─────────┴───────────────────╯
```

## Step 6: Verify Interfaces

```bash
docker exec clab-ceos-lab-ceos1 Cli -c "show interfaces status"
```

### Expected Output

```
Port       Name   Status       Vlan     Duplex Speed  Type
Et1               connected    1        full   1G     EbraTestPhyPort
Et2               connected    1        full   1G     EbraTestPhyPort
Et3               connected    1        full   1G     EbraTestPhyPort
Et4               connected    1        full   1G     EbraTestPhyPort
Et5               connected    1        full   1G     EbraTestPhyPort
Ma0               connected    routed   a-full a-1G   10/100/1000
```

## Step 7: Access the Switches

```bash
# Interactive CLI access
docker exec -it clab-ceos-lab-ceos1 Cli
docker exec -it clab-ceos-lab-ceos2 Cli

# SSH access (if configured)
ssh admin@clab-ceos-lab-ceos1
ssh admin@clab-ceos-lab-ceos2
```

---

## Lab Lifecycle Commands

```bash
# Check lab status
clab inspect --topo topo.yml

# Destroy the lab
clab destroy --topo topo.yml

# Destroy and redeploy (clean restart)
clab destroy --topo topo.yml && clab deploy --topo topo.yml
```

## Full Cleanup (Remove Everything)

```bash
# Destroy the lab
clab destroy --topo topo.yml

# Remove the Docker image
docker rmi ceos:latest

# Clean up Docker
docker system prune -f

# Remove lab files
rm -rf clab-ceos-lab/
```

---

## Quick Access from Mac (One-Command SSH)

Instead of SSH-ing into the VM and running `docker exec` each time, set up
passwordless access so you can type `ceos1` or `ceos2` directly from your Mac.

### Step 1: Copy Your SSH Key to the VM

```bash
ssh-copy-id -o StrictHostKeyChecking=no root@10.100.168.51
# Enter VM password (arastra) when prompted — only needed once
```

### Step 2: Add VM Host Entry to `~/.ssh/config`

```
Host tac-route-gen
  HostName 10.100.168.51
  User root
  StrictHostKeyChecking no
```

### Step 3: Verify Passwordless SSH

```bash
ssh tac-route-gen hostname
# Should print: tac-route-gen (no password prompt)
```

### Step 4: Add Shell Aliases to `~/.zshrc`

```bash
# cEOS containerlab shortcuts (VM: 10.100.168.51)
alias ceos1='ssh -t tac-route-gen "docker exec -it clab-ceos-lab-ceos1 Cli"'
alias ceos2='ssh -t tac-route-gen "docker exec -it clab-ceos-lab-ceos2 Cli"'
alias clab-status='ssh tac-route-gen "cd /root/cEOS && clab inspect --topo topo.yml"'
```

Then reload: `source ~/.zshrc`

### Usage

| Command | What it does |
|---------|-------------|
| `ceos1` | Opens interactive EOS CLI on ceos1 |
| `ceos2` | Opens interactive EOS CLI on ceos2 |
| `clab-status` | Shows lab node status and IPs |
