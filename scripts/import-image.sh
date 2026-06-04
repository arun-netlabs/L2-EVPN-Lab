#!/bin/bash
# Import cEOS-lab rootfs tarball into Docker
# Usage: ./import-image.sh <path-to-cEOS-lab.tar.xz> [image:tag]

IMAGE_FILE="${1:?Usage: $0 <cEOS-lab.tar.xz> [image:tag]}"
IMAGE_TAG="${2:-ceos:latest}"

if [ ! -f "$IMAGE_FILE" ]; then
    echo "ERROR: File not found: $IMAGE_FILE"
    exit 1
fi

echo "Importing $IMAGE_FILE as $IMAGE_TAG ..."

docker import "$IMAGE_FILE" "$IMAGE_TAG" \
  --change 'CMD ["/sbin/init"]' \
  --change 'ENV INTFTYPE=eth' \
  --change 'ENV ETBA=1' \
  --change 'ENV SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1' \
  --change 'ENV CEOS=1' \
  --change 'ENV EOS_PLATFORM=ceoslab' \
  --change 'ENV container=docker'

echo ""
echo "Done. Verify with: docker images | grep ceos"
