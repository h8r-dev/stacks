#!/usr/bin/env bash

# The name of image pull secret
SECRET_NAME=regcred

# Update chart default values.
yq -i '
  .image.repository = "ghcr.io/'$USERNAME'/'$DIR_NAME'" |
  .image.tag = "'$TAG'" |
  .imagePullSecrets[0].name = "'$SECRET_NAME'" |
  .image.pullPolicy = "IfNotPresent"
' $APP_NAME/charts/$DIR_NAME/values.yaml

# Add image pull secret file into helm templates
kubectl create secret docker-registry $SECRET_NAME \
  --docker-server="ghcr.io" \
  --docker-username=$USERNAME \
  --docker-password=$PASSWORD \
  --dry-run=client \
  -o yaml > $APP_NAME/templates/imagepullsecret.yaml