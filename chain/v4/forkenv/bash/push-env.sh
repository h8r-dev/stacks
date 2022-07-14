#!/usr/bin/env bash

#ls -al /helm
git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_USER_EMAIL
deployRepo=""
for file in */ ;
do
    REPOSITORY_NAME=$(echo $file | tr -d '/')
    cd /helm/$file
    git remote set-url origin "https://$GITHUB_TOKEN@github.com/$GITHUB_ORGANIZATION/$REPOSITORY_NAME"
    if [[ "$file" == *"deploy"* ]]; then
        deployRepo="https://github.com/$GITHUB_ORGANIZATION/$REPOSITORY_NAME"
        git add .
        git commit -a -m 'Add new env: '$ENV_NAME --allow-empty
        git pull --rebase
        git push origin main
    else
        # try to push branch as env, if some branch has been checkout in add-values-file.sh
        if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
            git push origin $ENV_NAME
        fi
    fi
done

# Create env crd
kubectl apply -f /crd

# patch ApplicationSet
timestamp=$(date +%s)
kubectl annotate ApplicationSet $APP_NAME forkmain.dev/timestamp=$timestamp -n argocd

# Update Argocd applicationSet
# Make sure applicationSet yaml was exist uncoment it after yicai done deploy issue

# yq -i '
#   .metadata.name = "'$APP_NAME'" |
#   .spec.generators[0].git.repoURL = "'$deployRepo'" |
#   .spec.generators[0].git.files[0].path = "'$APP_NAME'/env/*/values.yaml" |
#   .spec.template.metadata.name = "{{path.basename}}-'$APP_NAME'" |
#   .spec.template.spec.destination.namespace = "'$APP_NAME'-{{path.basename}}" |
#   .spec.template.spec.source.repoURL = "'$deployRepo'" |
#   .spec.template.spec.source.path = "'$APP_NAME'"
# ' /argoappset/applicationset.yaml