# Go-gin-stack

## 功能预览

1. 检查前置条件
2. 自动创建 `Github` 仓库和初始化 `Helm Chart`
3. 部署
4. Nocalhost 一键开发和调试

### check.cue
前置检查 `infra`，是否配置了 `kubeconfig`，将来增加 `kubeconfig` 连通性检查。

### init_repp.cue
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
Output             Value  Description                                                                                                                                                                    
check_infra.check  OK!                                                                                     
deploy.install     nh4rtov.sh.office.h8r.com.cn   Application URL                                                                                                           
initRepo.gitUrl    https://github.com/lyzhang1999/orders2.git   Git URL    
```
