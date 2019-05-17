# 组件调试

<https://istio.io/zh/help/ops/component-debugging/>
<https://istio.io/zh/help/ops/traffic-management/proxy-cmd/>
<https://istio.io/zh/help/ops/traffic-management/observing/>

## 获取网格的状态

```shell
# 获取网格的概要情况
# 如果怀疑某个 Sidecar 无法获取配置，或者同步失败，就可以用这个命令来进行验证。
# 如果一个代理没有出现在这个列表上，就说明该代理目前没有连接到 Pilot 实例上，不会接到任何配置。
istioctl proxy-status
```

- SYNCED : Envoy 已经接收到了 Pilot 发送的最新配置。
- SYNCED (100%)  : Envoy 成功的同步了集群内的所有端点。
- NOT SENT : Pilot 尚未向 Envoy 发送任何数据，这通常是因为 Pilot 没有需要发送的内容。
- STALE : Pilot 已经向 Envoy 发出了更新，但是还没有收到响应。这很可能意味着 Envoy 和 Pilot 之间的网络存在故障，或者是 Istio 自身的 Bug，Pilot 需要扩容。

## 检索 Envoy 和 Istio Pilot 之间的差异

```shell
kubectl -n istio-samples get pod -l app=details
# 获取 Envoy 已经载入的配置和 Pilot 将要发送的配置之间的差异，这有助于识别同步失败的问题，并且对原因分析也有帮助。
istioctl proxy-status details-v1-57fd679d85-d6jdg.istio-samples
```

## Envoy 配置深度解析

```shell
kubectl -n istio-system get pod -l app=istio-ingressgateway
# 通过管理接口在 Envoy 中获取集群的配置，获取给定 pod 的集群、监听器或路由的基本摘要
istioctl -n istio-system proxy-config clusters istio-ingressgateway-7cbb75569d-jb5c6
```

## 追踪 Envoy 对请求（从 productpage Pod 发向 reviews Pod 上的 reviews:9080）

### 查询 Pod 的监听器概要信息

```shell
kubectl -n istio-samples get pod -l app=productpage
istioctl -n istio-samples proxy-config listeners productpage-v1-76786b6bd7-8zw75
```

- 0.0.0.0:15001 的监听器会接收所有出入 Pod 的流量，然后将请求转交给一个虚拟监听器。(IP tables)
- 服务 IP 的虚拟监听器，用于 TCP/HTTPS 的非 HTTP 出站流量。
- Pod IP 的虚拟监听器，用于暴露入站流量的端口。
- 0.0.0.0 的虚拟监听器用于出站的 HTTP 流量。

```shell
istioctl -n istio-samples proxy-config listeners productpage-v1-76786b6bd7-8zw75 --port 15001 -o json
```

- useOriginalDst 设置为 True，表明他会根据原始目的地来选择监听器，并将流量转发给最合适的监听器。
- 如果找不到匹配的虚拟监听器，就会把请求发送给 BlackHoleCluster，它会返回一个 404。

```shell
# 我们的请求是一个出站的 HTTP 请求，目标是 9080，因此这个请求应该提交给 0.0.0.0:9080 虚拟监听器
istioctl -n istio-samples proxy-config listeners productpage-v1-76786b6bd7-8zw75 --address 0.0.0.0 --port 9080 -o json
# 这个监听器会在它的 RDS 中查找路由配置，这个例子中，就是在 Pilot（通过 ADS）配置的 RDS 信息中查找 9080
```

```shell
# 9080 路由配置在每个服务中只有一个虚拟主机。
# 我们的请求是发向 reviews 服务的，所有 Envoy 会选择符合请求域名的虚拟主机。
# 选定虚拟主机之后，Envoy 会选择匹配该请求的第一条路由。
# 这里没有定义任何的高级路由，所以只有一个匹配所有请求的路由。这个路由告诉 Envoy 发送请求到 outbound|9080||reviews.istio-samples.svc.cluster.local 集群。
istioctl -n istio-samples proxy-config routes productpage-v1-76786b6bd7-8zw75 --name 9080 -o json
```

```shell
# 这个集群被配置从 Pilot（通过 ADS）获取端点列表。所以 Envoy 会使用 serviceName 字段作为关键字在端点列表中进行查找，然后将请求转发给查出来的端点中的一个。
istioctl -n istio-samples proxy-config clusters productpage-v1-76786b6bd7-8zw75 --fqdn reviews.istio-samples.svc.cluster.local -o json
```

```shell
# 可以使用 proxy-config endpoints 命令来查看当前集群的可用端点。
istioctl -n istio-samples proxy-config endpoints productpage-v1-76786b6bd7-8zw75 --cluster outbound\|9080\|\|reviews.istio-samples.svc.cluster.local
```

## 观察启动配置

```shell
kubectl -n istio-system get pod -l app=istio-ingressgateway
istioctl -n istio-system proxy-config bootstrap istio-ingressgateway-7cbb75569d-jb5c6
```

## 使用 GDB

要使用 gdb 调试 Istio，则需要运行 Envoy/Mixer/Pilot 的调试镜像。同时也需要新版本的 gdb 和 golang 扩展（用于 Mixer/Pilot 或其他 golang 组件）。

- kubectl exec -it PODNAME -c [proxy | mixer | pilot]
- 查找进程 ID：ps ax
- gdb -p PID binary
- 对于 go：info goroutines，goroutine x bt

## 使用 Tcpdump

Tcpdump 在 Sidecar 中不能工作 - 因为该容器不允许以 root 身份运行。但是由于同一 Pod 内会共享网络命名空间，因此 Pod 中的其他容器也能监听所有数据包。iptables 也能查看到 Pod 级别的相关配置。

Envoy 和应用程序之间的通信在地址 127.0.0.1 上进行，并且未进行加密。
