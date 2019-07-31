# 性能与可伸缩性

<https://istio.io/docs/concepts/performance-and-scalability/>
<https://github.com/istio/tools/tree/master/perf/load>
<https://mp.weixin.qq.com/s/bry4g11lacH1eyuh5uVcHw>

## 官方数据

Istio 负载测试网格由 1000 个服务和 2000 个 Sidecar 组成，每秒钟产生 70,000 个网格范围内的请求。在使用 Istio 1.1.7 完成测试之后，我们获得了以下结果：

- Envoy 在处理 1000 rps 的情况下，使用 0.6 个 vCPU 以及 50 MB 的内存。
- istio-telemetry 在每秒 1000 个 网格范围内的请求的情况下，消耗了 0.6 个 vCPU。
- Pilot 使用了 1 个 vCPU 以及 1.5 GB 的内存。
- Envoy 在第 90 个百分位上增加了 8 毫秒的延迟。

## 控制平面性能

## 数据平面性能

## 测试工具

- fortio.org：一个恒定吞吐量的负载测试工具。 <https://github.com/fortio/fortio>

```shell
brew install fortio
```

- blueperf：一个仿真的云原生应用。
- isotope：具备可配置拓扑结构的合成应用。

## 百万TPS

```shell
cd istio.io/tools/perf/load
./setup_large_test.sh 1

# 构造镜像 istio.io/tools/isotope
cd istio.io/tools/isotope
tahler/isotope-service:1
```
