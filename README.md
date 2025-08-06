# tor-v3-vanity for Docker

Deploy the GPU-powered tor-v3-vanity .onion generator as a Docker image. Originally intended for cloud GPU rentals, the image can now be used comfortably on a local Ubuntu host.

## Usage

Build the image:

```
docker build -t tor-v3-vanity .
```

Run with your desired prefix and a local directory to store generated keys:

```
mkdir -p keys
docker run --gpus all -e ONION_PREFIX=example -v "$(pwd)/keys:/root/tor-v3-vanity/mykeys" tor-v3-vanity
```

The container writes keys to `/root/tor-v3-vanity/mykeys`, which is bound to `./keys` on the host in this example.

