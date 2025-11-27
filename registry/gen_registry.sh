#!/bin/bash

REGISTRY_IP="10.0.100.152"
REGISTRY_PORT="4000"

#Install docker

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Registry
sudo mkdir -p /containers

sudo docker run -d -p ${REGISTRY_PORT}:5000 --restart=always --name registry -v /containers:/var/lib/registry registry

sudo mkdir -p /etc/docker
sudo bash -c "cat > /etc/docker/daemon.json <<EOF
{
  \"insecure-registries\": [\"${REGISTRY_IP}:${REGISTRY_PORT}\"]
}
EOF"

sudo systemctl restart docker
