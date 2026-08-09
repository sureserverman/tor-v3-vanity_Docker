#!/bin/bash
# Run the tor-v3-vanity image under podman or docker.
#
#   ./container.sh build              build (or rebuild) the image
#   ./container.sh PREFIX [OPTIONS]   run t3v, forwarding every argument
#
# Everything after the script name goes to t3v inside the container, so all of
# its flags work here: --bonus, --count, --algo, --help, and so on.
set -euo pipefail

IMAGE="${IMAGE:-tor-v3-vanity}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${KEYS_DIR:-$PWD/keys}"

# Engine selection. Held as an array so a multi-word value such as
# "sudo docker" stays several argv entries instead of collapsing into one
# command name that no shell can find.
if [ -n "${CONTAINER_ENGINE:-}" ]; then
    read -r -a ENGINE <<< "$CONTAINER_ENGINE"
elif command -v podman >/dev/null 2>&1; then
    ENGINE=(podman)
elif command -v docker >/dev/null 2>&1; then
    # Rootless docker needs no sudo; only reach for it if the daemon is out of
    # reach as the current user.
    if docker info >/dev/null 2>&1; then
        ENGINE=(docker)
    else
        ENGINE=(sudo docker)
    fi
else
    cat >&2 <<'EOF'
Neither podman nor docker was found in PATH.

Install one of them, for example:
  sudo apt-get install -y podman        # or
  sudo apt-get install -y docker.io

You will also need the NVIDIA container toolkit for GPU access:
  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

Then re-run this script, or set CONTAINER_ENGINE to the engine of your choice.
EOF
    exit 1
fi

build_image() {
    echo "Building $IMAGE with ${ENGINE[*]}..."
    "${ENGINE[@]}" build -t "$IMAGE" "$HERE"
}

if [ "${1:-}" = "build" ]; then
    build_image
    exit 0
fi

if ! "${ENGINE[@]}" image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Image $IMAGE not found."
    build_image
fi

mkdir -p "$KEYS_DIR"

run_args=(--rm -v "$KEYS_DIR:/keys")
if [ "${ENGINE[0]}" = "podman" ]; then
    # CDI device name, supported by podman 4.1+ with the NVIDIA container
    # toolkit configured. Older podman instead wants:
    #   --hooks-dir=/usr/share/containers/oci/hooks.d
    run_args+=(--device nvidia.com/gpu=all)
else
    run_args+=(--gpus all)
fi

# Interactive terminal gets the live dashboard; a pipe gets plain status lines.
if [ -t 1 ]; then
    run_args+=(-t)
fi

exec "${ENGINE[@]}" run "${run_args[@]}" "$IMAGE" "$@"
