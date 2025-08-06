FROM ubuntu:18.04

# Install CUDA 10.0
RUN apt-get update \
 && apt-get install -yq gpg curl \
 && apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub \
 && curl -LO http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb \
 && dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb \
 && rm -f cuda-repo-ubuntu1804_10.0.130-1_amd64.deb \
 && apt-get update \
 && apt-get install -yq cuda-libraries-dev-10-0

# Setup environment & deps
ADD mnt-run.sh /root/mnt-run.sh
RUN chmod +x /root/mnt-run.sh
ENV INSTALL_PATH=/root
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y curl apt-utils \
 && apt-get install -y git build-essential

# Install rust and NVPTX toolchain
ARG RUST_VERSION=nightly
ARG PTX_LINKER_VERSION=0.9.1
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION}
ENV PATH /root/.cargo/bin:$PATH
RUN rustup target add nvptx64-nvidia-cuda --toolchain ${RUST_VERSION}

# Install tor-v3-address (CUDA .onion generator)
RUN git clone https://github.com/dr-bonez/tor-v3-vanity ${INSTALL_PATH}/tor-v3-vanity \
 && mkdir ${INSTALL_PATH}/tor-v3-vanity/mykeys \
 && cd ${INSTALL_PATH}/tor-v3-vanity \
 && cargo +${RUST_VERSION} install ptx-linker --version ${PTX_LINKER_VERSION} \
 && cargo +${RUST_VERSION} install --path .

ENTRYPOINT ["/root/mnt-run.sh"]
