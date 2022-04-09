# stacks

Cloud native stacks for application development.

# Dev

1. `git clone --recursive git@github.com:h8r-dev/stacks.git`
  > If you have a repo cloned already, do `git submodule init && git submodule update`
2. change your `plans/cuelib` code
3. `hof mod vendor cue`
4. `dagger do up`

# Use remote buildkit

- Start buildkit:
```
ssh root@VPS_IP
nohup buildkitd --addr tcp://127.0.0.1:1234 > ~/buildkit.log 2>&1 &
```
- SSH port forward
```
ssh -L 1235:127.0.0.1:1234 $VPS_USER@$VPS_IP -N
```

- Execute plan
```
export BUILDKIT_HOST=tcp://127.0.0.1:1235
dagger do -p ./plans up
```