# Go-gin-stack

## Requirements
1. 一个公网可访问的 `K8s` 集群，且具备 `LoadBalancer` 能力
2. Kubenetes version > 1.13

## 已知问题
1. 每次运行将产生新的访问 URL
2. Infra 应用在初始化安装时，如时间超过 10 分钟（例如镜像拉取）则会导致失败
3. 只支持创建公开权限的仓库

## Quick Start

1. 处理依赖：`hof mod vendor cue`
2. 初始化：`dagger init`
3. 创建环境：`dagger new [ENV_NAME] -p ./plans`
4. 检查需要填充的变量：`dagger input list`
5. 填充变量：`dagger input text || dagger input dir || dagger input secret`
6. 运行：`dagger up`

## 初始化变量示例
```
dagger input secret helmDeploy.myKubeconfig -f /Users/wangwei/Downloads/test/test2
dagger input text initRepo.applicationName orders
dagger input secret initRepo.accessToken [Github personal access token]
dagger input text initRepo.organization [organization name or github id]
dagger input dir initRepo.sourceCodeDir .
```

## 功能预览

1. 检查前置条件
2. 自动创建 `Github` 仓库和初始化 `Helm Chart`：包含 `go-gin` 框架的后端仓库，`vue.js` 的前端仓库以及 `Helm` 仓库
3. 部署应用，支持 Ingress 访问(h8r.app)
4. 创建并配置 Infra 层应用，包括 Nocalhost、Loki、Prometheus、Grafana、Alertmanager，支持 Ingress 访问(h8r.io)
5. 使用 Github Organization 创建 Nocalhost 用户，初始化应用、集群、开发空间
6. Nocalhost 一键开发和调试
7. What's Next 指引

### Stack 参数
```
Input                     Value             Set by user  Description
helmDeploy.myKubeconfig   dagger.#Secret    true         Cluster kubeconfig
initRepo.applicationName  string            true         Application name, will be set as repo name
initRepo.accessToken      dagger.#Secret    true         Github personal access token, and will also use to pull ghcr.io image
initRepo.organization     string            true         Github organization name or username, currently only supported username
initRepo.sourceCodeDir    dagger.#Artifact  true         TODO default repoDir path, now you can set "." with dagger dir type
```

### check.cue
1. 计划增加 `kubeconfig` 连通性检查

### init.cue
1. 将 `Stack` 的 `go-gin` 目录初始化到目标仓库，并配置 `Github action` 以及调整 `Helm Chart` 参数
2. 初始化 `Nocalhost` 用户、应用、集群、开发空间信息

### deploy.cue
1. 使用目标仓库的 `Helm Chart` 部署到集群指定的 `Namespace`
2. 创建应用的 `H8r Ingress`

### infra.cue
1. 安装 `infra` 应用，包括 Nocalhost、Loki、Prometheus、Grafana 等
2. 创建目标集群 `Ingress`
3. 创建 `H8r Ingress`

### Stack 执行结果

```
Output                                                            Value                               Description
showAppDomain                                                     "production.sakgww.go-gin.h8r.app"  Show App domain
helmDeploy.install                                                "sakgww.go-gin.h8r.app"  Application URL
suffix.out                                                        "sakgww"                            generated random string
nocalhostDomain                                                   "sakgww.nocalhost.stack.h8r.io"     Nocalhost URL
grafanaDomain                                                     "sakgww.grafana.stack.h8r.io"       Grafana URL
prometheusDomain                                                  "sakgww.prom.stack.h8r.io"          Prometheus URL
alertmanagerDomain                                                "sakgww.alert.stack.h8r.io"         Alertmanager URL
installIngress.targetIngressEndpoint.get                          "129.226.98.247"  Ingress nginx endpoint
installLokiStack.grafanaIngressToTargetCluster.grafanaSecret.get  "qzMg8Q4XJIa4pm0nQppjysX5wLNDAaMFOV72KI83"  Grafana secret, password of admin user
initRepo.gitUrl                                                   "https://github.com/coding-spinnaker/orders22.git"  Git URL
initFrontendRepo.gitUrl                                           "https://github.com/coding-spinnaker/orders22-front.git"  Git URL
initHelmRepo.gitUrl                                               "https://github.com/coding-spinnaker/orders22-helm.git"  Git URL
```
