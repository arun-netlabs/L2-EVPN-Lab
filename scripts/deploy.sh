#!/bin/bash
# Deploy the L2 EVPN containerlab topology
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

cd "$LAB_DIR" || exit 1

# Check if ceos image exists
if ! docker images | grep -q "ceos"; then
    echo "ERROR: ceos Docker image not found."
    echo "Run: ./scripts/import-image.sh <path-to-cEOS-lab.tar.xz>"
    exit 1
fi

echo "Deploying L2 EVPN lab..."
clab deploy --topo topo.yml

echo ""
echo "Access the switches:"
echo "  docker exec -it clab-l2evpn-spine Cli"
echo "  docker exec -it clab-l2evpn-leaf1 Cli"
echo "  docker exec -it clab-l2evpn-leaf2 Cli"
echo ""
echo "Access the hosts:"
echo "  docker exec -it clab-l2evpn-host1 bash"
echo "  docker exec -it clab-l2evpn-host2 bash"
