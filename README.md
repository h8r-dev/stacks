# Stacks

Cloud native stacks for application development.

## Local Development

```shell
# Clone the repo if you do not have it.
# If you have a repo cloned already, run:
#   git submodule init && git submodule update
git clone --recursive git@github.com:h8r-dev/stacks.git

# Install dependencies
hof mod vendor cue && dagger project update
dagger do up
```

## Documentation

- [Stack documentation](https://heighliner.dev/docs/core_features/stacks/overview)
- Use [remote buildkit](https://heighliner.dev/docs/development/buildkit)
