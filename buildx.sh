docker buildx use localremote_builder

docker buildx build --push \
--builder localremote_builder \
--platform linux/amd64,linux/arm64 \
--tag pedromol/ubuntu-novnc:22.04 .
