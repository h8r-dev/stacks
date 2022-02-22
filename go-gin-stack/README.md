# Go-gin-stack

## Quick Start

1. 处理依赖：`hof mod vendor cue`
2. 初始化：`dagger init`
3. 创建环境：`dagger new [ENV_NAME] -p ./plans`
4. 检查需要填充的变量：`dagger input list`
5. 填充变量：`dagger input text || dagger input dir || dagger input secret`
6. 运行：`dagger up`


## 功能预览

1. 检查前置条件
2. 自动创建 `Github` 仓库和初始化 `Helm Chart`：包含 `go-gin` 框架的后端仓库，`vue.js` 的前端仓库以及`Helm` 仓库
3. 部署
4. Nocalhost 一键开发和调试

### Stack 参数
```
Input                     Value             Set by user  Description
deploy.ingressHostName    string            true         Ingress host name
deploy.kubeconfig         dagger.#Artifact  true         TODO Kubeconfig path, set infra/kubeconfig and fill kubeconfig to infra/kubeconfig/config.yaml file
deploy.namespace          string            true         Deploy namespace
initRepo.applicationName  string            true         Application name, will be set as repo name
initRepo.accessToken      dagger.#Secret    true         Github personal access token, and will also use to pull ghcr.io image
initRepo.organization     string            true         Github organization name, can be set with username
initRepo.sourceCodeDir    dagger.#Artifact  true         TODO default repoDir path, now you can set "." with dagger dir type
```

### check.cue
前置检查 `infra`，是否配置了 `kubeconfig`，将来增加 `kubeconfig` 连通性检查。

### init_repo.cue
将 `Stack` 的 `go-gin` 目录初始化到目标仓库，并配置 `Github action` 以及调整 `Helm Chart` 参数。

**注意：目前只能创建公开类型的仓库**

### deploy.cue
使用目标仓库的 `Helm Chart` 部署到集群指定的 `Namespace`。

### monitor.cue
**待完善**

### logs.cue
**待完善**

### alert.cue
**待完善**

### Stack 执行结果

```
Output                     Value  Description                                                                                                                                                                    
check_infra.check          OK!                                                                                     
deploy.install             nh4rtov.sh.office.h8r.com.cn   Application URL                                                                                                           
initRepo.gitUrl            https://github.com/lyzhang1999/orders.git   Git URL  
initFrontendRepo.gitUrl    https://github.com/lyzhang1999/orders-front.git   Git URL
initFrontendHelm.gitUrl    https://github.com/lyzhang1999/orders-helm.git   Git URL    
```
