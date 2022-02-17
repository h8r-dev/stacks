# Go-gin-stack

### check.cue
前置检查 `infra`，是否配置了 `kubeconfig`，将来增加 `kubeconfig` 连通性检查。

### init_repp.cue
将 `Stack` 的 `go-gin` 目录初始化到目标仓库，并配置 `Github action` 以及调整 `Helm Chart` 参数。

**注意：目前只能创建公开类型的仓库**

### deploy.cue
使用目标仓库的 `Helm Chart` 部署到集群指定的 `Namespace`。

### Stack 执行结果

```
Output             Value  Description                                                                                                                                                                    
check_infra.check  OK!                                                                                     
deploy.install     nh4rtov.sh.office.h8r.com.cn   Application URL                                                                                                           
initRepo.gitUrl    https://github.com/lyzhang1999/orders2.git   Git URL    
```