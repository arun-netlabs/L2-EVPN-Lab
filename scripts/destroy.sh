#!/bin/bash
# Destroy the L2 EVPN containerlab topology
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

cd "$LAB_DIR" || exit 1

echo "Destroying L2 EVPN lab..."
clab destroy --topo topo.yml --cleanup
