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
	//   RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
	//   RUN sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
	//   RUN apt-get update && apt install curl wget jq git apt-transport-https gnupg npm tar unzip -y
	//   # install terraform
	//   RUN wget https://releases.hashicorp.com/terraform/1.1.9/terraform_1.1.9_linux_amd64.zip && unzip terraform_1.1.9_linux_amd64.zip && mv terraform /usr/local/bin/
	//   # install nodejs 12
	//   RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
	//   # set yarn config
	//   RUN npm install -g yarn
	//   RUN yarn config set registry https://registry.npm.taobao.org/
	//   # github-cli
	//   RUN curl -sSL -O https://github.com/cli/cli/releases/download/v2.8.0/gh_2.8.0_linux_amd64.tar.gz && tar -zxvf gh_2.8.0_linux_amd64.tar.gz && mv gh_2.8.0_linux_amd64/bin/gh /usr/local/bin/gh
	//   # argocd cli
	//   RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.3.3/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd
	//   # kubectl
	//   RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	//   # install helm
	//   RUN curl -fL "https://h8r-generic.pkg.coding.net/release/generic/helm-v3.8.2-linux-amd64.tar.gz?version=latest" -o helm-v3.8.2-linux-amd64-latest.tar.gz && tar -zxvf helm-v3.8.2-linux-amd64-latest.tar.gz && mv helm /usr/local/bin/helm
	//   # yq
	//   RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.24.5/yq_linux_amd64 && chmod a+x /usr/local/bin/yq
	//   """
	// }
	build: docker.#Pull & {
		source: "lyzhang1999/ubuntu:latest@sha256:5737397f85dfe16b5c3174f1b58914259902a58e3574d2b60d5ddf5e532e27de"
	}
	output: build.output
}
