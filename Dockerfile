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

# Setup our environment & deps
ADD mnt-run.sh /root/mnt-run.sh
RUN chmod +x /root/mnt-run.sh
ENV INSTALL_PATH=/root
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y curl apt-utils;\
apt-get install -y git build-essential;\
\
# Install tor-v3-address (CUDA .onion generator) \
git clone https://github.com/dr-bonez/tor-v3-vanity ${INSTALL_PATH}/tor-v3-vanity;\
mkdir  ${INSTALL_PATH}/tor-v3-vanity/mykeys;\
\
# Install rust \
echo "Change is coming...";\
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y;\
. $HOME/.cargo/env;
ENV PATH /root/.cargo/bin:$PATH
RUN cargo install ptx-linker
RUN rustup toolchain add nightly-2020-01-02 \
&& rustup target add nvptx64-nvidia-cuda --toolchain nightly-2020-01-02;\
# curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y;\
cd ${INSTALL_PATH}/tor-v3-vanity;\
# export PATH="$HOME/.cargo/bin:$PATH";\
rustup install nightly;\
rustup target add nvptx64-nvidia-cuda;\
cargo install ptx-linker;\
cargo +nightly install --path .

# Set script that will execute when end-user runs container
ENTRYPOINT ["/root/mnt-run.sh"]
