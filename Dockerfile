# tor-v3-vanity as a container image.
#
# Two stages: a CUDA toolkit + nightly Rust builder, and a thin runtime holding
# only the binary. libcuda.so.1 is deliberately NOT baked in — it belongs to the
# host driver and is injected at run time by the NVIDIA container runtime.

ARG CUDA_VERSION=12.6.3
ARG UBUNTU_VERSION=24.04

# ---------------------------------------------------------------- builder ----
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS builder

ARG RUST_VERSION=nightly
ARG REPO=https://github.com/sureserverman/tor-v3-vanity
ARG REF=master
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
      ca-certificates curl git build-essential \
 && rm -rf /var/lib/apt/lists/*

# pipefail so a failed download can't be piped into a shell that exits 0 and
# bakes a toolchain-less image.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain ${RUST_VERSION} --profile minimal
ENV PATH=/root/.cargo/bin:$PATH

# The GPU kernel is compiled separately for nvptx64 and linked with Rust's
# llvm-bitcode-linker. The legacy ptx-linker is not used and must not be
# installed. rust-src is required because the kernel builds core from source.
RUN rustup target add nvptx64-nvidia-cuda --toolchain ${RUST_VERSION} \
 && rustup component add llvm-bitcode-linker llvm-tools rust-src \
      --toolchain ${RUST_VERSION}

# Link against the CUDA driver stub. The real library arrives from the host at
# run time; linking against the stub keeps the driver out of the image.
ENV CUDA_LIB_DIR=/usr/local/cuda/lib64/stubs

# --locked: build exactly the dependency versions the repo committed.
RUN git clone --depth 1 --branch ${REF} ${REPO} /src \
 && cargo +${RUST_VERSION} install --locked --path /src/rust --root /usr/local \
 && strip /usr/local/bin/t3v

# ---------------------------------------------------------------- runtime ----
FROM ubuntu:${UBUNTU_VERSION} AS runtime

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install --no-install-recommends -y ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Tells the NVIDIA container runtime which devices and driver features to wire
# in. Without compute+utility the container gets no libcuda.so.1 and t3v exits
# reporting no CUDA devices.
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    OUTPUT_DIR=/keys

COPY --from=builder /usr/local/bin/t3v /usr/local/bin/t3v
COPY mnt-run.sh /usr/local/bin/mnt-run.sh

RUN chmod 0755 /usr/local/bin/mnt-run.sh /usr/local/bin/t3v \
 && mkdir -p /keys

# Secret keys land here. Bind-mount it, or they vanish with the container.
VOLUME ["/keys"]
WORKDIR /keys

ENTRYPOINT ["/usr/local/bin/mnt-run.sh"]
