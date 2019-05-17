# 调试授权

<https://istio.io/help/ops/security/debugging-authorization/>

## 确保授权功能已经正确启用

ClusterRbacConfig 是一个集群级的单例 CRD，用于控制全局的授权功能。

```shell
kubectl get clusterrbacconfigs.rbac.istio.io --all-namespaces
```

这里应该只有一个 ClusterRbacConfig 实例，其名称应该是 default。否则 Istio 会禁用授权功能并忽略所有策略。

如果上面步骤中出现了不止一个的 ClusterRbacConfig 实例，请删除其它的 ClusterRbacConfig，保证集群之中只有一个名为 default 的 ClusterRbacConfig。

## 检查 Pilot 的工作状态

Pilot 负责对授权策略进行转换，并将其传播给 Sidecar。下面的的步骤可以用于确认 Pilot 是否能够正常工作

- 导出 Pilot 的 ControlZ

```shell
kubectl port-forward $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -n istio-system 9876:9876
```

- 用浏览器打开 http://127.0.0.1:9876/scopez/，浏览 ControlZ 页面
  - 将 rbac Output Level 修改为 debug

- 步骤 1 中打开的终端窗口中输入 Ctrl+C，终止端口转发进程

- 输出 Pilot 日志，在其中搜索 rbac

```shell
kubectl logs $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system | grep rbac
```

## 确认 Pilot 正确的将策略分发给了代理服务器

- 获取 productpage 服务的代理配置信息

```shell
kubectl -n istio-samples exec  $(kubectl -n istio-samples get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl localhost:15000/config_dump -s
```

## 确认策略在代理服务器中正确执行

- 在代理中打开授权调试日志

```shell
kubectl -n istio-samples exec  $(kubectl -n istio-samples get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -X POST localhost:15000/logging?rbac=debug -s
```

- 检查输出内容是否包含如下内容

```yaml
active loggers:
  ... ...
  rbac: debug
  ... ...
```

- 在浏览器中打开 productpage，以便生成日志。

- 用命令输出代理日志

```shell
kubectl -n istio-samples logs $(kubectl -n istio-samples get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
```

- 检查日志内容
  - 输出日志中可能包含 enforced allowed 或者 enforced denied，表示请求被允许或者拒绝。
  - 授权策略需要从请求中获取数据。
