#!/bin/bash
# Wrapper script to use either podman or docker as container engine.
set -e

# If CONTAINER_ENGINE is set, use it. Otherwise, prefer podman if available.
ENGINE="${CONTAINER_ENGINE}"
if [ -z "$ENGINE" ]; then
  if command -v podman >/dev/null 2>&1; then
    ENGINE="podman"
  elif command -v docker >/dev/null 2>&1; then
    ENGINE="sudo docker"
  else
    echo "Neither podman nor docker is available in PATH."
    echo "Do you want to install podman or docker?"
    echo "D is for docker, P is for podman, or any other key to exit."
    read -r -n 1 -p "Choose an option: " choice
    echo
    case "$choice" in
        [Dd]* ) echo "Installing docker..."; sudo apt-get install -y docker; ENGINE="sudo docker";;
        [Pp]* ) echo "Installing podman..."; sudo apt-get install -y podman; ENGINE="podman";
                # Ensure podman is set up to use the GPU if available.
                if ! grep -q 'nvidia.com/gpu' /etc/containers/oci/hooks.d/oci-systemd-hook.json; then
                  echo "Configuring podman for GPU access..."
                  sudo mkdir -p /etc/containers/oci/hooks.d
                  echo '{
                    "version": "1.0.0",
                    "hook": {
                      "path": "/usr/bin/nvidia-container-runtime-hook",
                      "args": [],
                      "env": []
                    }
                  }' | sudo tee /etc/containers/oci/hooks.d/oci-systemd-hook.json >/dev/null
                fi;;
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

if [ "$ENGINE" == "podman" ]; then
  # Podman requires the --hooks-dir option to be set for GPU access.
  runargs="--hooks-dir=/usr/share/containers/oci/hooks.d --device nvidia.com/gpu=all -e ONION_PREFIX=$1 -v \"$(pwd)/keys:/root/tor-v3-vanity/mykeys\" tor-v3-vanity"
else
  # Docker does not require the --hooks-dir option.
  runargs="--rm --gpus all -e ONION_PREFIX=$1 -v \"$(pwd)/keys:/root/tor-v3-vanity/mykeys\" tor-v3-vanity"
fi

# Execute the chosen engine with all passed arguments.
exec "$ENGINE" "run" "$runargs"
