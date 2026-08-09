# tor-v3-vanity for Containers

Run the GPU-powered [tor-v3-vanity](https://github.com/sureserverman/tor-v3-vanity)
`.onion` generator as a container image. Originally built for cloud GPU rentals,
it works just as well on a local host with either Docker or Podman.

## Requirements

- An NVIDIA GPU of compute capability 7.5 (Turing) or newer, plus the
  proprietary driver.
- Docker or Podman.
- The [NVIDIA container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html),
  so the container can reach the GPU. `libcuda.so.1` is not baked into the
  image — it comes from the host driver at run time.

## Usage

`container.sh` picks Podman when available and falls back to Docker; override
with `CONTAINER_ENGINE`. Every argument you pass is handed straight to `t3v`,
so all of its options work:

```bash
mkdir -p keys

# One prefix
./container.sh myprefix

# Several at once, two matches each
./container.sh myprefix,otherprefix --count 2

# Take a longer prefix only if it happens to turn up
./container.sh myprefix --bonus mylongerprefix

# The original, slower search kernel
./container.sh --algo seed myprefix

# Anything t3v understands
./container.sh --help
```

The image is built automatically on first run. To rebuild it explicitly:

```bash
./container.sh build
```

Keys are written to `/keys` in the container, bind-mounted to `./keys` on the
host. Point `KEYS_DIR` somewhere else if you prefer:

```bash
KEYS_DIR=/secure/vault ./container.sh myprefix
```

Each key file is written mode 0600 and named after the address it produces. Use
one as a Tor hidden service identity:

```bash
cp keys/myprefix....onion /var/lib/tor/hidden_service/hs_ed25519_secret_key
```

## Calling the engine directly

`container.sh` is only a convenience. The equivalent long forms:

```bash
# Docker
docker run --rm --gpus all -v "$PWD/keys:/keys" tor-v3-vanity myprefix --count 2

# Podman (4.1+ with CDI configured)
podman run --rm --device nvidia.com/gpu=all -v "$PWD/keys:/keys" \
    tor-v3-vanity myprefix --count 2
```

Older Podman without CDI wants the OCI hooks directory instead of `--device`:

```bash
podman run --rm --hooks-dir=/usr/share/containers/oci/hooks.d \
    -v "$PWD/keys:/keys" tor-v3-vanity myprefix
```

## Build options

`docker build` accepts a few `--build-arg` values:

| Arg | Default | Purpose |
| --- | --- | --- |
| `REPO` | `https://github.com/sureserverman/tor-v3-vanity` | Source repository |
| `REF` | `master` | Branch or tag to build |
| `RUST_VERSION` | `nightly` | Toolchain (the NVPTX target is nightly-only) |
| `CUDA_VERSION` | `12.6.3` | CUDA toolkit image tag used for the build stage |
| `UBUNTU_VERSION` | `24.04` | Base image release |

## Notes on the keys this produces

The default `incremental` search kernel stores the secret **scalar** un-clamped,
which is what Tor does with the on-disk key. Any tool that re-derives the
address by clamping — `ed25519-dalek`'s `ExpandedSecretKey` conversion among
them — will silently compute a *different* address from the same file. Tor
itself is unaffected. See the upstream README for how to verify a key
independently.

## Changes from earlier versions of this image

- Arguments are forwarded to `t3v` instead of being taken from a single
  `ONION_PREFIX` variable, so `--bonus`, `--count` and `--algo` are usable.
  `ONION_PREFIX` still works, with `T3V_ARGS` for extra flags.
- Keys are written to **`/keys`**, not `/root/tor-v3-vanity/mykeys`. Update any
  `-v` flags you have scripted.
- The image builds from this fork rather than upstream `dr-bonez`, and uses
  Rust's `llvm-bitcode-linker` rather than the retired `ptx-linker`. The build
  stage moved from Ubuntu 18.04 / CUDA 10.0 to the official CUDA image, and the
  runtime stage now carries only the binary.
- `container.sh` no longer offers to install a container engine; it prints what
  to install instead. The old prompt installed the wrong Debian package.
