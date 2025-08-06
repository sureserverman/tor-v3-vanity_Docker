# tor-v3-vanity for Containers

Deploy the GPU-powered tor-v3-vanity .onion generator as a container image. Originally intended for cloud GPU rentals, the image can now be used comfortably on a local Ubuntu host with either Docker or Podman.

## Usage

The script `container.sh` automatically selects `podman` when available, falling back to `docker`. You can override the choice by setting the `CONTAINER_ENGINE` environment variable.

### Build the image

```
./container.sh build -t tor-v3-vanity .
```

### Run with your desired prefix and a local directory to store generated keys

```
mkdir -p keys
./container.sh run --rm --gpus all -e ONION_PREFIX=example -v "$(pwd)/keys:/root/tor-v3-vanity/mykeys" tor-v3-vanity
```

For Podman users with NVIDIA GPUs, you may need to include the NVIDIA container hooks:

```
./container.sh run --hooks-dir=/usr/share/containers/oci/hooks.d --device nvidia.com/gpu=all -e ONION_PREFIX=example -v "$(pwd)/keys:/root/tor-v3-vanity/mykeys" tor-v3-vanity
```

The container writes keys to `/root/tor-v3-vanity/mykeys`, which is bound to `./keys` on the host in these examples.
