# Stacks

Cloud native stacks for application development.

## Local Development

```shell
# Clone the repo or just do `git pull`
git clone git@github.com:h8r-dev/stacks.git

# Install `air` to watch files change.
go install github.com/cosmtrek/air@latest

# Watch files and Develop
make watch
```

## Run test
```shell
cd cuelib
dagger project update && dagger do test -p ./utils/status/test --log-format plain
```

## Documentation

- [Stack documentation](https://heighliner.dev/docs/core_features/stacks/overview)
- Use [remote buildkit](https://heighliner.dev/docs/development/buildkit)
