#!/usr/bin/env bash

#cd "$APP_NAME"/charts/"$DIR_NAME"
#set="yq -i $HELM_SET values.yaml"
#eval $set
yq -i '.image.repository = "ghcr.io/'$USERNAME'/'$DIR_NAME'" | .image.tag = "'$TAG'" | .imagePullSecrets[0].name="regcred"' "$APP_NAME"/charts/"$DIR_NAME"/values.yaml
# Add image pull secret file
kubectl create secret docker-registry regcred --docker-server="ghcr.io" --docker-username=$USERNAME --docker-password=$PASSWORD --dry-run=client -o yaml > "$APP_NAME"/templates/imagepullsecret.yaml