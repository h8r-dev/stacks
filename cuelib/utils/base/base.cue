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
	//    FROM ubuntu@sha256:31cd7bbfd36421dfd338bceb36d803b3663c1bfa87dfe6af7ba764b5bf34de05
	//    ENV DEBIAN_FRONTEND=noninteractive
	//    RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
	//    RUN sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
	//    RUN apt-get update && apt install curl wget jq git apt-transport-https gnupg npm tar -y
	//    # install nodejs 12
	//    RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
	//    # set yarn config
	//    RUN npm install -g yarn
	//    RUN yarn config set registry https://registry.npm.taobao.org/
	//    # github-cli
	//    RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	//    # argocd cli
	//    RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.3.3/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd
	//    # kubectl
	//    RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
	//    # install helm
	//    RUN curl https://baltocdn.com/helm/signing.asc | apt-key add -
	//    RUN echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
	//    RUN apt-get update && apt install gh kubectl helm -y
	//    # yq
	//    RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.24.5/yq_linux_amd64 && chmod a+x /usr/local/bin/yq
	//   """
	// }
	build: docker.#Pull & {
		source: "lyzhang1999/ubuntu:latest"
	}
	output: build.output
}
