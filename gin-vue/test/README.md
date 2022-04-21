# Stack Testing

Stack testing is based on [ginkgo framework](https://onsi.github.io/ginkgo/).
Each test is an e2e test that verifies the given stack is running correctly.

## Setup

Go to the test directory:

```shell
# Suppose you are in stacks repo
cd gin-vue/test
```

### Install ginkgo:

```shell
go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo
go get github.com/onsi/gomega/...
```

This fetches Ginkgo and installs the ginkgo executable under `$GOBIN` - you'll want that on your `$PATH`. It also fetches the core Gomega matcher library and its set of supporting libraries.

### Install [hln](https://heighliner.dev/docs/getting_started/installation) 

Learn more about [how to use hln](https://heighliner.dev/docs/cli/hln/overview).

## Run

Before running the tests, you need to run the stack first:

> Set up the environment variables that stack required properly.

```shell
# Go to the gin-vue stack directory
cd ..
hln up
```

Then run the e2e tests:

```shell
# Go to the test directory
cd test/
ginkgo
```

Clean up your app

```shell
# Go to the gin-vue stack directory
cd ..
hln down
```