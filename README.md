# Stacks

Cloud native stacks for application development.

## Local Development

```shell
# Clone the repo if you do not have it.
# If you have a repo cloned already, run:
git clone git@github.com:h8r-dev/stacks.git

# Install dependencies
cd gin-next
hof mod vendor cue && dagger project update
dagger do up -p ./plans --log-format plain
```
## Run test
```shell
cd cuelib
dagger project update && dagger do test -p ./utils/status/test --log-format plain
```

## Documentation

- [Stack documentation](https://heighliner.dev/docs/core_features/stacks/overview)
- Use [remote buildkit](https://heighliner.dev/docs/development/buildkit)
