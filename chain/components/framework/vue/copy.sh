#!/usr/bin/env bash

npm config set registry http://mirrors.cloud.tencent.com/npm/
echo "Y" | vue create $APP_NAME -d --no-git
cat <<EOF >  /scaffold/$APP_NAME/$APP_NAME-cd-output-hook.txt
{"type": "frontend"}
EOF

