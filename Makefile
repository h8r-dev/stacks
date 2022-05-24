SHELL := bash# we want bash behaviour in all shell invocations

# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
BOLD := \033[1m
NORMAL := \033[0m
GREEN := \033[1;32m

XDG_CONFIG_HOME ?= $(CURDIR)/.config
export XDG_CONFIG_HOME
.DEFAULT_GOAL := help
HELP_TARGET_DEPTH ?= \#

HOF_VER ?= 0.6.1

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

.PHONY: help
help: # Show how to get started & what targets are available
	@printf "This is a list of all the make targets that you can run, e.g. $(BOLD)make dagger$(NORMAL) - or $(BOLD)m dagger$(NORMAL)\n\n"
	@awk -F':+ |$(HELP_TARGET_DEPTH)' '/^[0-9a-zA-Z._%-]+:+.+$(HELP_TARGET_DEPTH).+$$/ { printf "$(GREEN)%-20s\033[0m %s\n", $$1, $$3 }' $(MAKEFILE_LIST) | sort
	@echo
	
.PHONY: cuefmt
cuefmt: install-cue # Format all cue files
	@find . -name '*.cue' -not -path '*/cue.mod/*' -print | xargs -n 1 -P 8 cue fmt -s

.PHONY: cuelint
cuelint: cuefmt eval # Lint and format all cue files
	@test -z "$$(git status -s . | grep -e "^ M"  | grep "\.cue" | cut -d ' ' -f3 | tee /dev/stderr)"

find_ignore_names := ! -name '.*' ! -name 'tars' ! -name 'tmp' ! -name 'scripts' ! -name 'cue.mod' ! -name 'chain' ! -name 'cuelib'
.PHONY: eval
eval: vendor # Run cue eval to check all plans
	@cd ./official-stack && find . -maxdepth 1 -mindepth 1 -type d \
	 $(find_ignore_names) \
 	 -print0 | xargs -I {} -n 1 -0 bash -c 'cd {} && cue eval ./plans > /dev/null'

# Watch cuelib files change, and install new codes into stack cude.mod folder automatically.
# Firstly: Execute `go install github.com/cosmtrek/air@latest` to install `air`.
.PHONY: watch
watch: install_air # Watch the cuelib dir and rerender when cuelib changes.
	ulimit -n 10240 && air

.PHONY: tar
tar: vendor install_yq # Pack stacks into ./tars dir
	@bash ./scripts/process_stacks.sh --pack

.PHONY: vendor
vendor: install-hof install-dagger # Install or update cue module dependencies.
	@bash ./scripts/process_stacks.sh -i

.PHONY: update-index
update-index: # Update official stacks' index
	@bash ./scripts/process_stacks.sh --update-index

.PHONY: check-index
check-index:
	@bash ./scripts/process_stacks.sh --check-index

.PHONY: install-hooks
install-hooks: # Install git hooks
	git config core.hooksPath ./.git-hooks

.PHONY: install-cue
install-cue: # Install cue
	@which cue || go install cuelang.org/go/cmd/cue@latest

.PHONY: install-hof
install-hof: 
ifeq ($(shell which hof),)
	@curl -LO https://github.com/hofstadter-io/hof/releases/download/v${HOF_VER}/hof_${HOF_VER}_$(shell uname)_x86_64
	@mkdir -p ${GOBIN}
	@mv hof_${HOF_VER}_$(shell uname)_x86_64 ${GOBIN}/hof
	@chmod +x ${GOBIN}/hof
endif

.PHONY: install-dagger
install-dagger:
ifeq ($(shell which dagger),)
	@curl -L https://dl.dagger.io/dagger/install.sh | sh
	@mv ./bin/dagger ${GOBIN}/dagger
endif

.PHONY: install_air
install_air:
	which air || go install github.com/cosmtrek/air@latest

.PHONY: install_yq
install_yq:
	which yq || go install github.com/mikefarah/yq/v4@latest