#!/bin/bash
# Wrapper script to use either podman or docker as container engine.
set -e

# If CONTAINER_ENGINE is set, use it. Otherwise, prefer podman if available.
ENGINE="${CONTAINER_ENGINE}"
if [ -z "$ENGINE" ]; then
  if command -v podman >/dev/null 2>&1; then
    ENGINE=podman
  elif command -v docker >/dev/null 2>&1; then
    ENGINE=docker
  else
    echo "Error: neither podman nor docker was found in PATH" >&2
    exit 1
  fi
fi

# Execute the chosen engine with all passed arguments.
exec "$ENGINE" "$@"
