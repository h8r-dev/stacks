#!/usr/bin/env bash

# wait until argocd is ready
echo "Waiting for argocd to be ready"
curl --retry 300 --retry-delay 2 "$ARGO_SERVER" --fail --insecure >> /dev/null 2>&1
echo 'y' | argocd login "$ARGO_SERVER" --username "$ARGO_USERNAME" --password "$PASSWORD" --insecure --grpc-web

# Add argocd repo
retry_count=0
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

# Create argocd application
create_argocd_app() {
	NAME=$1
	APP_DIR=$2
	DEST_NAMESPACE=$3

	retry_count=0

	echo "creating argocd app: $NAME"

	while ! argocd app create "$NAME" \
		--repo "$REPO_URL" \
		--path "$APP_DIR" \
		--dest-server "$APP_SERVER" \
		--dest-namespace "$DEST_NAMESPACE" \
		--sync-option CreateNamespace=true \
		--sync-policy automated \
		--grpc-web \
		--insecure \
		--plaintext;
	do
		if [ $retry_count -ge 10 ]; then
			echo "Create argocd app: $NAME failed."
			exit 1
		fi
		sleep 5
		((retry_count+=1))
		echo "Waiting for creating argocd app: $NAME"
	done
}

# Create business applications for ArgoCD
create_argocd_app "$APP_NAME" "$APP_PATH" "$APP_NAME-$APP_NAMESPACE"

