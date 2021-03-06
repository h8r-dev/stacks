#!/usr/bin/env bash

set -e

name=$1
ingress_http_port=$2
ingress_https_port=$3
kube_apiserver_port=$4
buildkit_port=$5

export KUBECONFIG="$HOME/.kube/config-${name}"

# create kind cluster
cat <<EOF | kind create cluster --name "${name}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: ${ingress_http_port}
    protocol: TCP
  - containerPort: 443
    hostPort: ${ingress_https_port}
    protocol: TCP
  - containerPort: 6443
    hostPort: ${kube_apiserver_port}
    protocol: TCP
  - containerPort: 31234
    hostPort: ${buildkit_port}
    protocol: TCP
EOF

ls -l "$HOME/.kube"
