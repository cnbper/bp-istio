# istio-proxy

```shell
# 查看 istio-proxy 日志
kubectl -n istio-samples get pod
kubectl -n istio-samples logs -f reviews-v2-95f489c6b-fwds8 istio-proxy

# 进入 istio-proxy
kubectl -n istio-samples exec -it reviews-v2-95f489c6b-fwds8 -c istio-proxy sh

# 获取 istio-proxy 配置
ns=foo && kubectl -n $ns exec $(kubectl -n $ns get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl localhost:15000/config_dump -s
```

## 开启debug日志

```shell
# http
ns=foo && kubectl -n $ns exec $(kubectl -n $ns get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -X POST localhost:15000/logging?http=debug -s

# rbac
ns=foo && kubectl -n $ns exec $(kubectl -n $ns get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -X POST localhost:15000/logging?rbac=debug -s
```

## 调试 Envoy 和 Pilot

## Envoy proxy is NOT ready: config not received from Pilot (is Pilot running?)

### [warning][config] [bazel-out/k8-opt/bin/external/envoy/source/common/config/_virtual_includes/grpc_stream_lib/common/config/grpc_stream.h:86] gRPC config stream closed: 14, upstream connect error or disconnect/reset before headers. reset reason: connection failure

- 解决方案
