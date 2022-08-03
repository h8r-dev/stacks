#!/usr/bin/env bash

# merge all charts
echo "create parent chart"
mkdir -p /tmp
helm create /tmp/"$APP_NAME"
# remove default template
rm -rf /tmp/"$APP_NAME"/templates/*
# clean values.yaml
:> /tmp/"$APP_NAME"/values.yaml

# move all charts to charts folder
for dir in */; do
  if [ -d "$dir" ]; then
    echo "move $dir"
    mv "$dir" /tmp/"$APP_NAME"/charts
  fi
done
mkdir "$APP_NAME"
mv /tmp/"$APP_NAME" .

# nocalhost dev config
mkdir -p .nocalhost
touch .nocalhost/config.yaml
yq -i '.configProperties.version = "v2"' .nocalhost/config.yaml
yq -i '.application.helmValues += [{"key": "global.nocalhost.enabled","value": true}]' .nocalhost/config.yaml

# set parent values
for dir in "$APP_NAME/charts/"*; do
  if [ -d "$dir" ]; then
    value="$dir/values.yaml"
    if [ -f "$value" ]; then
    name="${dir##*/}"
    echo echo "set $name values to parent chart"
    yq -i '."'$name'" = load("'${value}'")' "$APP_NAME/values.yaml"
    fi
  fi
done
yq -i 'del(.. | select(has("global")).global)' "$APP_NAME/values.yaml"
