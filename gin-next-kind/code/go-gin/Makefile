
# Image URL to use all building/pushing image targets
IMG ?= go-gin:latest

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
# This is a requirement for 'setup-envtest.sh' in the test target.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.PHONY: all
all: build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

SWAGGER = $(shell pwd)/bin/swag
.PHONY: api-docs
api-docs: swag ## Create swagger docs.go.
	$(SWAGGER) init

.PHONY: swag
swag: ## Download swag locally if necessary.
	$(call go-get-tool,$(SWAGGER),github.com/swaggo/swag/cmd/swag@v1.8.0)

.PHONY: fmt
fmt: ## Run go fmt against code.
	go fmt ./...

.PHONY: vet
vet: ## Run go vet against code.
	go vet ./...

.PHONY: tidy
tidy: ## Run go mod tidy.
	go mod tidy

.PHONY: vendor
vendor: ## Run go mod vendor.
	go mod vendor

##@ Build

.PHONY: build
build: fmt vet ## Build manager binary.
	go build -o bin/go-gin main.go

.PHONY: run
run: fmt vet ## Run a controller from your host.
	go run ./main.go

.PHONY: docker-build
docker-build: ## Build docker image with the manager.
	docker build -t ${IMG} .

.PHONY: docker-push
docker-push: ## Push docker image with the manager.
	docker push ${IMG}

##@ Deployment

ifndef ignore-not-found
  ignore-not-found = false
endif

NAMESPACE ?= h8r-system
.PHONY: deploy
deploy: ## Deploy go-gin to the K8s cluster specified in ~/.kube/config.
	kubectl create namespace ${NAMESPACE}
	kubectl apply -n ${NAMESPACE} -f ./deploy

.PHONY: undeploy
undeploy: ## Undeploy go-gin from the K8s cluster specified in ~/.kube/config. Call with ignore-not-found=true to ignore resource not found errors during deletion.
	kubectl delete -n ${NAMESPACE} --ignore-not-found=$(ignore-not-found) -f ./config

# go-get-tool will 'go get' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-get-tool
@[ -f $(1) ] || { \
set -e ;\
GOBIN=$(PROJECT_DIR)/bin go install $(2) ;\
}
endef
