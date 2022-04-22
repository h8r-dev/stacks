# gin-next-europa Stack
1. 声明式
1. 支持 Kind
1. Buildkit 运行在集群内
1. 使用 ArgoCD 管理所有部署
1. 不依赖 H8r Server，内部使用 Service Name 访问，外部使用 Hosts 访问
1. 支持应用组合、添加应用（待完善）
1. 优化运行体验和提升运行速度
  1. 自定义执行镜像
  1. 删除不必要的等待

## Requirements

1. Kind v0.12.0+
1. Docker, **Docker daemon resource setting > 8C, 16G**
1. Kubectl v1.20+

## 注意
1. 开启全局代理会导致本地 Hosts 配置失效，无法通过默认域名访问
1. Github Personal Access Token(PAT) 将会存储在集群和仓库中，公开仓库可能会导致凭据泄露

## 已知问题
1. 初始化完成后，添加新的应用或 Addons 不会生效
1. 未初始化 Nocalhost 数据
1. 后端服务缺少配置，无法启动
1. Release 流程未处理
1. 暂时缺少 `output.yaml` 输出

## Quick Start

1. 安装 Kind：https://kind.sigs.k8s.io/docs/user/quick-start/#installation
1. 创建 Kind 集群
    ```
    cat <<EOF | kind create cluster --config=-
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
      kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
      extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
      - containerPort: 31234
        hostPort: 1234
    EOF
    ```
1. 部署 Buildkit(考虑自动化)
    ```shell
    kubectl apply -f https://raw.githubusercontent.com/h8r-dev/stacks/main/gin-next-europa/resources/buildkit.yaml
    # waiting for ready
    kubectl wait --for=condition=Available deployment buildkitd --timeout 600s
    ```
1. 导出 Kind kubeconfig，并修改 API Server 地址(考虑自动化)
    ```shell
    kubectl config view --flatten --minify | sed -e 's?server: https://127.0.0.1:[0-9]*?server: https://kubernetes.default.svc?' > ~/.kube/kind
    ```
1. 初始化参数：

    ```shell
    export BUILDKIT_HOST=tcp://127.0.0.1:1234
    export KUBECONFIG=~/.kube/kind
    export APP_NAME="orders"
    export GITHUB_TOKEN=[Github personal access token]
    export ORGANIZATION=[organization name or github id]
    export CLOUD_PROVIDER=kind
    ```

1. 运行：`dagger do up -p ./plans`

1. 确认 Ingress nginx Ready
    ```shell
    kubectl wait --for=condition=Available deployment ingress-nginx-controller -n ingress-nginx --timeout 600s
    ```
1. Ingress-nginx Ready，添加 Hosts，打开浏览器访问
    ```shell
    127.0.0.1 argocd.h8r.infra
    127.0.0.1 orders-frontend.h8r.application
    127.0.0.1 orders-backend.h8r.application
    127.0.0.1 grafana.h8r.infra
    127.0.0.1 alert.h8r.infra
    127.0.0.1 prometheus.h8r.infra
    ```

1. 删除: `dagger do down -p ./plans`