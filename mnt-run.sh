#!/bin/bash


# Specify required environment variables
ENV_VARS=(
    "DO_KEY"
    "DO_SECRET"
    "DO_SPACE"
    "DO_REGION"
    "ONION_PREFIX"
    "INSTALL_PATH"
)

# Check that all necessary environment varialbes are set
for e in "${ENV_VARS[@]}"; do
    [[ -v $e ]] || { echo "Error $e"; exit 0; }
done

# Add DO Spaces API key & secret from env
echo "$DO_KEY:$DO_SECRET" > ~/.passwd-s3fs && chmod 600 ~/.passwd-s3fs;\

# Mount the DO space (s3 bucket)
s3fs "${DO_SPACE}" ${INSTALL_PATH}/tor-v3-vanity/mykeys \
-o passwd_file=~/.passwd-s3fs \
-o "url=https://${DO_REGION}.digitaloceanspaces.com/" \
-o use_path_request_style \
&& \

# Run the CUDA .onion v3 generator storing results in DO space/bucket
~/tor-v3-vanity/t3v --dst "${INSTALL_PATH}/tor-v3-vanity/mykeys" "$ONION_PREFIX";
