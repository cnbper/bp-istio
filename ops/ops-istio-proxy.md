# istio-proxy

```shell
# 调整镜像地址
sed -i '' "s/docker.io\/kennethreitz/registry.sloth.com\/ipaas/g" istio-release/samples/httpbin/httpbin.yaml
sed -i '' "s/governmentpaas/registry.sloth.com\/ipaas/g" istio-release/samples/sleep/sleep.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples
 labels:
    istio-injection: enabled
EOF
kubectl -n samples apply -f istio-release/samples/httpbin/httpbin.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-1
 labels:
    istio-injection: enabled
EOF
kubectl -n samples-1 apply -f istio-release/samples/sleep/sleep.yaml

kubectl -n samples-1 patch svc sleep -p "{\"metadata\":{\"annotations\":{\"networking.istio.io/exportTo\":\".\"}}}"

kubectl -n samples-1 patch svc sleep -p "{\"metadata\":{\"annotations\":{\"networking.istio.io/exportTo\":\"*\"}}}"

cat <<EOF | kubectl -n istio-system apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
spec:
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
EOF
```

## 基本操作

```shell
# 查看 istio-proxy 日志
kubectl -n samples logs -f $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) istio-proxy
kubectl -n samples-1 logs -f $(kubectl -n samples-1 get pod -l app=sleep -o jsonpath={.items..metadata.name}) istio-proxy

# 进入 istio-proxy
kubectl -n samples exec -it $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy sh

# 获取 istio-proxy 配置
kubectl -n samples exec -it $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl localhost:15000/config_dump -s

# 暴露管理端口 https://www.envoyproxy.io/docs/envoy/latest/api-v2/api
kubectl -n samples port-forward $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) 15000:15000
# http://localhost:15000/stats/prometheus
# http://localhost:15000/config_dump

# 可以使用 proxy-config endpoints 命令来查看当前集群的可用端点。
istioctl -n samples proxy-config endpoints $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) --cluster outbound\|8000\|\|httpbin.samples.svc.cluster.local
```

## istio-proxy资源占用过多问题

- CPU 内存占用情况

```shell
docker ps | grep k8s_istio-proxy_httpbin
docker stats f0edec51258a

CONTAINER ID    CPU %    MEM USAGE / LIMIT    MEM %    NET I/O    BLOCK I/O    PIDS
f0edec51258a    0.30%    26.14MiB / 1GiB      2.55%    0B / 0B    0B / 0B      23
```

- Envoy配置中的Listener、Cluster、Endpoint数量

```shell
# 获取 listener 信息  | 23-1 | 24-1
istioctl -n samples proxy-config listeners $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) | wc -l

# 获取 cluster 信息  | 33-1 | 34-1
istioctl -n samples proxy-config clusters $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) | wc -l

# 获取 endpoint 信息  | 31-1 | 32-1
istioctl -n samples proxy-config endpoints $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) | wc -l
```

- 减少TCMalloc预留系统内存

```shell
# 通过Envoy的管理端口查看上面环境中一个Envoy内存分配的详细情况：
kubectl -n samples exec -it $(kubectl -n samples get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl localhost:15000/memory
{
 "allocated": "7960080",        // generic.current_allocated_bytes Envoy实际占用内存
 "heap_size": "11534336",       // generic.heap_size TCMalloc预留的系统内存
 "pageheap_unmapped": "0",      // tcmalloc.pageheap_unmapped_bytes
 "pageheap_free": "1941504",    // tcmalloc.pageheap_free_bytes
 "total_thread_cache": "1016312"// tcmalloc.current_total_thread_cache_bytes The amount of memory used by the TCMalloc thread caches (for small objects).
}
# 各个指标的详细说明参见Envoy文档 https://www.envoyproxy.io/docs/envoy/latest/api-v2/admin/v2alpha/memory.proto.html
# 由于Envoy采用了TCMalloc作为内存管理器，导致其占用内存大于Envoy实际使用内存。 https://gperftools.github.io/gperftools/tcmalloc.html
# https://wallenwang.com/2018/11/tcmalloc/
# TCMalloc的内存分配效率比glibc的malloc更高，但会预留系统内存，导致程序占用内存大于其实际所需内存。

# Envoy占用的内存大小和其配置相关，和请求处理速率无关。在一个较大的namespace中，Envoy大约占用50M内存。然而对于多大为“较大”，Istio官方文档并未给出一个明确的数据。
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

## upstream connect error or disconnect/reset before headers. reset reason: connection failure

