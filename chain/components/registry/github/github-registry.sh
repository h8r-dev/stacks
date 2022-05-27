#!/usr/bin/env bash

# Set the name of image pull secret.
IMAGE_PULL_SECRET_NAME="${APP_NAME}"
# Set kubeconfig path
export KUBECONFIG="/kubeconfig"
# Set seale secret parameter
export SEALED_SECRET_PATH="/sealed-secrets/${APP_NAME}"
export NAMESPACE="sealed-secrets"
export SECRETNAME="sealed-secret-${APP_NAME}"
export PRIVATEKEY="${SEALED_SECRET_PATH}/sealed-secret.key"
export PUBLICKEY="${SEALED_SECRET_PATH}/sealed-secret.crt"
export IMAGE_PULL_SECRET="${SEALED_SECRET_PATH}//imagepullsecret.yaml"
export ENCRYPTED_IMAGE_PULL_SECRET="${APP_NAME}/templates/sealed-image-pull-secret.yaml"

mkdir -p "${SEALED_SECRET_PATH}"

# check if the kubeconfig exists
if [[ ! -f "${KUBECONFIG}" ]]; then
    echo "can not find kubeconfig"
    exit 1
fi

# Get sealed-secrets certificate file from K8S secret if it exists.
# Generate new certificate file if it doesn't exist.
set +e
kubectl create namespace "${NAMESPACE}" > /dev/null 2>&1
kubectl -n "${NAMESPACE}" get secret "${SECRETNAME}" > /dev/null 2>&1
exit_code=$?
set -e

if [[ "$exit_code" == "0" ]]; then
  echo "get sealed secrets certificate file from K8S secret."
  kubectl -n "${NAMESPACE}" get secret "$SECRETNAME" -o json > "${SEALED_SECRET_PATH}/${SECRETNAME}".json
  < "${SEALED_SECRET_PATH}/${SECRETNAME}.json" jq -r '.data."tls.key"' | base64 --decode > "${PRIVATEKEY}"
  < "${SEALED_SECRET_PATH}/${SECRETNAME}.json" jq  -r '.data."tls.crt"' | base64 --decode > "${PUBLICKEY}"
else
  # Generate sealed-secrets certificate file.
  echo "generate sealed-secrets certificate file."
  openssl genrsa -out "${PRIVATEKEY}" 4096
  openssl req -x509 -new -nodes -key "${PRIVATEKEY}" -days 3650 -out "${PUBLICKEY}" -subj "/CN=sealed-secret/O=sealed-secret"
  # Create sealed secrets.
  echo "create sealed secrets."
  kubectl -n "${NAMESPACE}" create secret tls "${SECRETNAME}" --cert="${PUBLICKEY}" --key="${PRIVATEKEY}"
  kubectl -n "${NAMESPACE}" label secret "${SECRETNAME}" sealedsecrets.bitnami.com/sealed-secrets-key=active
  # Deleting the controller Pod is needed to pick they new keys
  set +e
  kubectl -n "${NAMESPACE}" delete pod -l app.kubernetes.io/name=sealed-secrets > /dev/null 2>&1
  set -e
fi

# Generate image pull secret.
kubectl create secret docker-registry "${IMAGE_PULL_SECRET_NAME}" \
  --docker-server="ghcr.io" \
  --docker-username="${USERNAME}" \
  --docker-password="${PASSWORD}" \
  --dry-run=client \
  -o yaml > "${IMAGE_PULL_SECRET}"

# Encrypt image pull secret
echo "generate encrypted image pull secret."
kubeseal --format yaml --scope cluster-wide --cert "${PUBLICKEY}" <"${IMAGE_PULL_SECRET}" >"${ENCRYPTED_IMAGE_PULL_SECRET}"

# Update chart default values.
yq -i '
  .image.repository = "ghcr.io/'"${USERNAME}"'/'"${DIR_NAME}"'" |
  .image.tag = "'"${TAG}"'" |
  .imagePullSecrets[0].name = "'"${IMAGE_PULL_SECRET_NAME}"'" |
  .image.pullPolicy = "IfNotPresent"
' "${APP_NAME}/charts/${DIR_NAME}/values.yaml"
