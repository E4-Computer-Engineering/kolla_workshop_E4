#!/bin/bash

REGISTRY_IP="10.0.100.152"
REGISTRY_PORT="4000"

sudo mkdir -p /containers

sudo docker run -d -p ${REGISTRY_PORT}:5000 --restart=always --name registry -v /containers:/var/lib/registry registry

sudo mkdir -p /etc/docker
sudo bash -c "cat > /etc/docker/daemon.json <<EOF
{
  \"insecure-registries\": [\"${REGISTRY_IP}\"]
}
EOF"

sudo systemctl restart docker