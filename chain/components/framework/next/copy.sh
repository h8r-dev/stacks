#!/usr/bin/env bash

sed -i "s/appname/$APP_NAME/" /scaffold/$APP_NAME/package.json
cat <<EOF >  /scaffold/$APP_NAME/$APP_NAME-cd-output-hook.txt
{"type": "frontend"}
EOF

