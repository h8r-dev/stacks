#!/usr/bin/env bash

cp /kubeconfig /origina_kubeconfig
server=$(kubectl config view --minify --kubeconfig /kubeconfig | awk '/server: /{print $2}')
printf '%s' "$server" > /api_server
< /kubeconfig sed 's#server: https://.*#server: https://kubernetes.default.svc#' > /new_kubeconfig

