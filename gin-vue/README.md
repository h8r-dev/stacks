# gin-vue Stack

## Requirements

1. 一个公网可访问的 `K8s` 集群，版本 1.20+，且具备 `LoadBalancer` 能力
1. kubectl
1. `hln` CLI

## 已知问题

1. 每次运行将产生新的访问 URL
1. Infra 应用在初始化安装时，如时间超过 10 分钟（例如镜像拉取）则会导致失败
1. 只支持创建公开权限的仓库

## Quick Start

1. 处理依赖：`hof mod vendor cue`
1. 初始化参数：

    ```shell
    export KUBECONFIG=[your kubeconfig path]
    export APP_NAME="orders"
    export GITHUB_TOKEN=[Github personal access token]
    export GITHUB_ORG=[organization name or github id]
    ```

1. 运行：`dagger do up -p ./plans/up.cue`
1. 删除: `dagger do down -p ./plans/down.cue`

## 功能预览

1. 检查前置条件
2. 自动创建 `Github` 仓库和初始化 `Helm Chart`：包含 `go-gin` 框架的后端仓库，`vue.js` 的前端仓库以及 `Helm` 仓库
3. 部署应用，支持 Ingress 访问(h8r.app)
4. 创建并配置 Infra 层应用，包括 Nocalhost、Loki、Prometheus、Grafana、Alertmanager，支持 Ingress 访问(h8r.io)
5. 使用 Github Organization 创建 Nocalhost 用户，初始化应用、集群、开发空间
6. Nocalhost 一键开发和调试

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

TODO: key=value 方式写到本地文件或 /dev/stdout

```shell
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
