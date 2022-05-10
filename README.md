# Stacks

Heighliner stacks to speed up app dev.

## Local Development

```shell
# Clone the repo or just do `git pull`
git clone git@github.com:h8r-dev/stacks.git

# Install git hooks
make install-hooks
```

If you want to live reload the chain modules, you need to [install go](https://go.dev/doc/install) and [setup GOPATH and GOBIN env](https://go.dev/doc/code) first.
Then run:

```shell
# Watch files and develop
make watch
```

## Layout

- **chain/**:
		This contains the chain (CUE) modules.
- **official-stack**:
		This contains the official stacks.

## Documentation

- [Stack documentation](https://heighliner.dev/docs/core_features/stacks/overview)
- [Getting started](https://heighliner.dev/docs/getting_started/installation)

## Repo Structure

This repo provides the following CUE modules:

- The entire repo can be imported as a CUE module.
- Each stack can be imported as a CUE module.
- The cuelib can be imported as a CUE module.

This repo contains the following stacks:

- [sample](./official-stack/sample/)
- [gin-vue](./official-stack/gin-vue/)
- [gin-next](./official-stack/gin-next/)
- [spring-vue](./official-stack/spring-vue/)
