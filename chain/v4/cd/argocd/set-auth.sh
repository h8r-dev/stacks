#!/usr/bin/env bash

ARGO_SERVER=$(echo "$ARGO_VAR" | yq '.url')
ARGO_USERNAME=$(echo "$ARGO_VAR" | yq '.credentials.username')
PASSWORD=$(echo "$ARGO_VAR" | yq '.credentials.password')

if [ -z "$ARGO_SERVER" ] || [ -z "$ARGO_USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "Missing ArgoCD config"
  exit 1
fi

# wait until argocd is ready
echo "Waiting for argocd to be ready..."
curl --retry 300 --retry-delay 2 "$ARGO_SERVER" --fail --insecure >> /dev/null 2>&1
echo "Argocd is ready."
echo 'y' | argocd login "$ARGO_SERVER" --username "$ARGO_USERNAME" --password "$PASSWORD" --insecure --grpc-web

# Add argocd repo
retry_count=0
echo "add repo url: $REPO_URL"
while ! argocd repo add "$REPO_URL" --username "x-access" --password "$REPO_PASSWORD"
do
	if [ $retry_count -ge 10 ]; then
		echo "Add git repo to argocd failed."
		exit 1
	fi
	((retry_count+=1))
	sleep 5
	echo 'Waiting for repository to be ready'
done