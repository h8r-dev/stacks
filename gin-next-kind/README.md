# gin-next-kind Stack

## Requirements

1. Kind v0.12.0+
1. Docker, **Docker daemon resource setting > 8C, 16G**
1. Kubectl v1.20+

## 注意
1. 开启全局代理会导致本地 Hosts 配置失效，无法通过默认域名访问
1. Github Personal Access Token(PAT) 将会存储在集群和仓库中，公开仓库可能会导致凭据泄露

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
1. 部署 Buildkit
    ```shell
    kubectl apply -f https://raw.githubusercontent.com/h8r-dev/stacks/main/gin-next-kind/resources/buildkit.yaml
    # waiting for ready
    kubectl wait --for=condition=Available deployment buildkitd --timeout 600s
    ```
1. 导出 Kind kubeconfig，并修改 API Server 地址
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