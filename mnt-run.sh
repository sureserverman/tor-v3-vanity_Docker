#!/bin/bash
set -e

# Default installation and output locations
INSTALL_PATH=${INSTALL_PATH:-/root}
OUTPUT_DIR=${OUTPUT_DIR:-${INSTALL_PATH}/tor-v3-vanity/mykeys}

# Ensure an onion prefix has been provided
if [[ -z "$ONION_PREFIX" ]]; then
    echo "Error: ONION_PREFIX is not set" >&2
    exit 1
fi

# Create destination directory and run the generator
mkdir -p "$OUTPUT_DIR"
~/tor-v3-vanity/t3v --dst "$OUTPUT_DIR" "$ONION_PREFIX"
