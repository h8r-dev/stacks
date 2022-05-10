#!/usr/bin/env bash

cat /infra/argocd/secret
deployRepoPath=$(cat /h8r/application)
cd /scaffold/$deployRepoPath
ls

# for output
mkdir -p /hln
touch /hln/output.yaml
yq -i '.cd.provider = "argocd"' /hln/output.yaml
yq -i '.cd.namespace = "argocd"' /hln/output.yaml
yq -i '.cd.type = "application"' /hln/output.yaml
yq -i '.cd.dashboardRef.url = "'$ARGO_URL'"' /hln/output.yaml
yq -i '.cd.dashboardRef.credential.username = "'$ARGO_USERNAME'"' /hln/output.yaml
export ARGO_PASSWORD=$(cat /infra/argocd/secret)
yq -i '.cd.dashboardRef.credential.password = "'$ARGO_PASSWORD'"' /hln/output.yaml

# Helm sets
setOps=""
if [[ $HELM_SET ]]; then
	echo 'helm values set'
	for i in $(echo $HELM_SET | tr "," "\n")
	do
		setOps="$setOps --helm-set "$i""
	done
fi

repoURL=$(git config --get remote.origin.url | tr -d '\n')
# wait until argocd is ready
curl --retry 300 --retry-delay 2 $ARGO_SERVER --fail --insecure >> /dev/null 2>&1
echo 'y' | argocd login "$ARGO_SERVER" --username "$ARGO_USERNAME" --password "$(cat /infra/argocd/secret)" --insecure --grpc-web

# Add argocd repo
retry_count=0
while ! argocd repo add $repoURL --username $(cat /scm/github/organization) --password $(cat /scm/github/pat)
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

	while ! argocd app create $NAME \
		--repo $repoURL \
		--path $APP_DIR \
		--dest-server $APP_SERVER \
		--dest-namespace $DEST_NAMESPACE \
		--sync-option CreateNamespace=true \
		--sync-policy automated \
		--grpc-web \
		--insecure \
		--plaintext \
		--upsert \
		$setOps;
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
# look for directory, ignore files
for file in */ ;
do
	APP_NAME=$(echo $file | tr -d '/')

	if [ ! -d $file ] || [ $APP_NAME == "infra" ]; then
		continue
	fi

	# For output
	if [ -f "$APP_NAME-cd-output-hook.txt" ]; then
		info=$(cat $APP_NAME-cd-output-hook.txt)
		echo "info: $info"
		yq -i '.cd.applicationRef += [{"name": "'$APP_NAME'", "info": "'$info'"}]' /hln/output.yaml
	else
		yq -i '.cd.applicationRef += [{"name": "'$APP_NAME'"}]' /hln/output.yaml
	fi

	create_argocd_app $APP_NAME $file "$deployRepoPath-$APP_NAMESPACE"
done

# Create infra applications for ArgoCD, if infra directory don't existed, exit now.
INFRA_DIR="infra"
if [ ! -d $INFRA_DIR ]; then
	exit 0
fi

cd $INFRA_DIR
for file in */ ;
do
	if [ ! -d $file ]; then
		continue
	fi

	APP_NAME=$(echo $file | tr -d '/')

	# For output
	if [ -f "$APP_NAME-cd-output-hook.txt" ]; then
		yq -i '.cd.applicationRef += [{"name": "'$APP_NAME'"}]' /hln/output.yaml
		info=$(cat $APP_NAME-cd-output-hook.txt)
		echo "info: $info"
		for key in `cat $APP_NAME-cd-output-hook.txt | jq keys | jq '.[]'`
		do
			echo $key
			key=$(echo $key | sed 's/\"//g')
			val=$(cat $APP_NAME-cd-output-hook.txt | jq .$key)
			echo "val:$val"
			val=$(echo $val | sed 's/\"//g')
			yq -i '.cd.applicationRef.[-1]."'$key'"="'$val'"' /hln/output.yaml
		done
	else
		yq -i '.cd.applicationRef += [{"name": "'$APP_NAME'"}]' /hln/output.yaml
	fi

	create_argocd_app $APP_NAME "$INFRA_DIR/$APP_NAME" $APP_NAME
done
