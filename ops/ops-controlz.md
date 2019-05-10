# 组件内检 controlz

<https://istio.io/zh/help/ops/controlz/>

Istio 的组件使用了一种灵活的内检（Introspection）框架构建，因此可以方便地查看和调整正在运行中组件的内部状态。 组件会开启一个端口，用来通过浏览器得到查看组件状态的交互式视图，或者供外部工具通过 REST 接口进行连接和控制。

Mixer[policy,telemetry]、Pilot 和 Galley 都实现了 ControlZ 功能。这些组件启动时将打印一条日志，提示通过 ControlZ 进行交互需连接到的 IP 地址和端口。

```shell
kubectl -n istio-system get pod -o wide
kubectl -n istio-system port-forward istio-citadel-787cbb899c-wc54w 9876:9876

# http://127.0.0.1:9876/
```
