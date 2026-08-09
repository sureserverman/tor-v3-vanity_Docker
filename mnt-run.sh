#!/bin/bash
# Container entrypoint: hand everything through to t3v.
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-/keys}"
mkdir -p "$OUTPUT_DIR"

usage() {
    cat >&2 <<EOF
No prefix given.

Usage:
  <engine> run --rm --gpus all -v "\$PWD/keys:/keys" tor-v3-vanity PREFIX [OPTIONS]

Examples:
  ... tor-v3-vanity myprefix
  ... tor-v3-vanity myprefix,otherprefix --count 2
  ... tor-v3-vanity myprefix --bonus mylongerprefix
  ... tor-v3-vanity --algo seed myprefix
  ... tor-v3-vanity --help

Keys are written to $OUTPUT_DIR inside the container; bind-mount it to keep
them. Set OUTPUT_DIR to write somewhere else.
EOF
    exit 2
}

# Arguments given to the container go straight to t3v, so every flag the CLI
# grows keeps working without editing this script. --dst is supplied only when
# the caller has not chosen one, because t3v rejects it twice.
have_dst() {
    for a in "$@"; do
        case "$a" in
            -d|--dst|--dst=*) return 0 ;;
        esac
    done
    return 1
}

if [ "$#" -gt 0 ]; then
    if have_dst "$@"; then
        exec t3v "$@"
    fi
    exec t3v --dst "$OUTPUT_DIR" "$@"
fi

# Backwards compatibility with the older env-var interface. T3V_ARGS carries
# any extra flags, e.g. T3V_ARGS="--count 3 --bonus mylongerprefix".
if [ -n "${ONION_PREFIX:-}" ]; then
    # shellcheck disable=SC2086  # T3V_ARGS is deliberately word-split
    exec t3v --dst "$OUTPUT_DIR" ${T3V_ARGS:-} "$ONION_PREFIX"
fi

usage
