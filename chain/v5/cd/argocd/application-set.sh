#! /usr/bin/env bash

echo "Apply ApplicationSet ${NAME}"

yq -i '
  .metadata.name = "'"${NAME}"'" |
  .spec.generators[0].git.repoURL = "'"${REPO}"'" |
  .spec.generators[0].git.files[0].path = "'"${NAME}"'/env/*/values.yaml" |
  .spec.template.metadata.name = "{{path.basename}}-'"${NAME}"'" |
  .spec.template.spec.destination.namespace = "'"${NAME}"'-{{path.basename}}" |
  .spec.template.spec.source.repoURL = "'"${REPO}"'" |
  .spec.template.spec.source.path = "'"${NAME}"'"
' ./application-set.yaml

kubectl -n ${NAMESPACE} apply -f ./application-set.yaml