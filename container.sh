#!/bin/bash
# Wrapper script to use either podman or docker as container engine.
set -e

# If CONTAINER_ENGINE is set, use it. Otherwise, prefer podman if available.
ENGINE="${CONTAINER_ENGINE}"
if [ -z "$ENGINE" ]; then
  if command -v podman >/dev/null 2>&1; then
    ENGINE="podman run --hooks-dir=/usr/share/containers/oci/hooks.d --device nvidia.com/gpu=all -e ONION_PREFIX=$1 -v \"$(pwd)/keys:/root/tor-v3-vanity/mykeys\" tor-v3-vanity"
  elif command -v docker >/dev/null 2>&1; then
    ENGINE="sudo docker run --rm --gpus all -e ONION_PREFIX=$1 -v \"$(pwd)/keys:/root/tor-v3-vanity/mykeys\" tor-v3-vanity"
  else
    echo "Neither podman nor docker is available in PATH."
    echo "Do you want to install podman or docker?"
    echo "D is for docker, P is for podman, or any other key to exit."
    read -r -n 1 -p "Choose an option: " choice
    echo
    case "$choice" in
        [Dd]* ) echo "Installing docker..."; sudo apt-get install -y docker;;
        [Pp]* ) echo "Installing podman..."; sudo apt-get install -y podman;;
        * ) echo "Error: neither podman nor docker was found in PATH" >&2; exit 1;;
    esac
  fi
fi

#Check if  the image is already built
IMAGENAME="tor-v3-vanity"
if ! $ENGINE image inspect "$IMAGENAME" >/dev/null 2>&1; then
  echo "Image $IMAGENAME not found. Building the image..."
  $ENGINE build -t "$IMAGENAME" .
fi

# Execute the chosen engine with all passed arguments.
exec "$ENGINE" "$@"
