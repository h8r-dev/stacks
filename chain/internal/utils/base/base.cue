package base

import (
	//"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Image: {
	// For development

	// build: docker.#Dockerfile & {
	//  source: dagger.#Scratch
	//  dockerfile: contents: """
	//   FROM ubuntu@sha256:31cd7bbfd36421dfd338bceb36d803b3663c1bfa87dfe6af7ba764b5bf34de05
	//   ENV DEBIAN_FRONTEND=noninteractive
	//   ENV PATH="/usr/local/lib/nodejs/node-v16.15.0-linux-x64/bin:${PATH}"
	//   RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
	//   RUN sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
	//   RUN apt-get update && apt install curl wget jq git apt-transport-https gnupg npm tar unzip -y && apt-get remove --purge nodejs -y && rm -rf /var/lib/apt/lists/*
	//   # install terraform
	//   RUN wget https://releases.hashicorp.com/terraform/1.1.9/terraform_1.1.9_linux_amd64.zip && unzip terraform_1.1.9_linux_amd64.zip && mv terraform /usr/local/bin/ && rm terraform_1.1.9_linux_amd64.zip
	//   # install nodejs 12
	//   RUN mkdir -p /usr/local/lib/nodejs
	//   RUN curl -sSL -O https://nodejs.org/dist/v16.15.0/node-v16.15.0-linux-x64.tar.xz && tar -xJvf node-v16.15.0-linux-x64.tar.xz -C /usr/local/lib/nodejs && rm node-v16.15.0-linux-x64.tar.xz
	//   # set yarn config
	//   RUN npm config set registry https://registry.npm.taobao.org && npm install -g yarn && npm install -g @vue/cli
	//   # RUN yarn config set registry https://registry.npm.taobao.org/
	//   # github-cli
	//   RUN curl -sSL -O https://github.com/cli/cli/releases/download/v2.8.0/gh_2.8.0_linux_amd64.tar.gz && tar -zxvf gh_2.8.0_linux_amd64.tar.gz && mv gh_2.8.0_linux_amd64/bin/gh /usr/local/bin/gh && rm gh_2.8.0_linux_amd64.tar.gz
	//   # argocd cli
	//   RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.3.3/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd
	//   # kubectl
	//   RUN curl -fL "https://h8r-generic.pkg.coding.net/release/generic/kubectl?version=v1.23.0" -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
	//   # install helm
	//   RUN curl -fL "https://h8r-generic.pkg.coding.net/release/generic/helm?version=v3.8.2" -o /usr/local/bin/helm && chmod +x /usr/local/bin/helm
	//   # yq
	//   RUN curl -fL "https://h8r-generic.pkg.coding.net/release/generic/yq_linux_amd64?version=v4.24.5" -o /usr/local/bin/yq && chmod a+x /usr/local/bin/yq
	//   """
	// }

	build: docker.#Pull & {
		source: "heighlinerdev/stack-base:debian"
	}

	output: build.output
}
