#!/usr/bin/env bash

set -e

KIND_VERSION=v0.12.0

# install docker
echo "Installing docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $(whoami)
echo "Docker installed ✅"

# install kind
echo "Installing Kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind version
echo "Kind installed ✅"
