# 灰度测试

```shell
# 调整镜像地址
sed -i '' "s/docker.io\/kennethreitz/registry.sloth.com\/ipaas/g" istio-release/samples/httpbin/httpbin.yaml
sed -i '' "s/governmentpaas/registry.sloth.com\/ipaas/g" istio-release/samples/sleep/sleep.yaml
sed -i '' "s/docker.io\/istio/registry.sloth.com\/ipaas/g" istio-release/samples/bookinfo/platform/kube/bookinfo.yaml
```

```shell
# 测试准备
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-gray
 labels:
    istio-injection: enabled
EOF
kubectl -n samples-gray apply -f istio-release/samples/sleep/sleep.yaml

# httpbin测试
## 网格内服务
kubectl -n samples-gray apply -f istio-release/samples/httpbin/httpbin.yaml
## 外部服务
cat <<EOF | kubectl -n samples-gray apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-org
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  resolution: DNS
EOF
## k8s服务
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-gray1
 labels:
    istio-injection: disable
EOF
kubectl -n samples-gray1 apply -f istio-release/samples/httpbin/httpbin.yaml

kubectl -n samples-gray exec $(kubectl -n samples-gray get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -i http://httpbin:8000/ip
kubectl -n samples-gray exec $(kubectl -n samples-gray get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -i http://httpbin.org/ip
kubectl -n samples-gray exec $(kubectl -n samples-gray get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -i http://httpbin.samples-gray1:8000/ip
istioctl -n samples-gray proxy-config clusters $(kubectl -n samples-gray get pod -l app=sleep -o jsonpath={.items..metadata.name})

cat <<EOF | kubectl -n samples-gray apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        port:
          number: 8000
      weight: 50
    - destination:
        host: httpbin.org
        port:
          number: 80
      weight: 50
EOF

cat <<EOF | kubectl -n samples-gray apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        port:
          number: 8000
      weight: 40
    - destination:
        host: httpbin.org
        port:
          number: 80
      weight: 30
    - destination:
        host: httpbin.samples-gray1.svc.cluster.local
        port:
          number: 8000
      weight: 30
EOF

cat <<EOF | kubectl -n samples-gray apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  http:
  - route:
    - destination:
        host: httpbin.org
        port:
          number: 80
      weight: 50
    - destination:
        host: httpbin.samples-gray1.svc.cluster.local
        port:
          number: 8000
      weight: 50
EOF

cat <<EOF | kubectl -n samples-gray apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.samples-gray1.svc.cluster.local
  http:
  - route:
    - destination:
        host: httpbin.org
        port:
          number: 80
      weight: 50
    - destination:
        host: httpbin.samples-gray1.svc.cluster.local
        port:
          number: 8000
      weight: 50
EOF
# 1.0 添加外部服务
# 1.1 部署k8s服务
# 1.2 部署网格主服务
# 1.3 部署网格灰度服务）
# 2 选择主服务
# 3 选择灰度版本

# nginx服务代理

# 端口？
# 灰度完成删除策略，灰度完成添加策略至全部流量到灰度版本
# 蓝绿发布（蓝namespace+蓝gateway，绿namespace+绿网关）
# 服务发布至蓝网关， 服务发布至绿网关
```

## Envoy Filter

<https://istio.io/docs/reference/config/networking/envoy-filter/>

```shell
kubectl -n samples-gray exec $(kubectl -n samples-gray get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -i http://httpbin:8000/ip

cat <<EOF | kubectl -n samples-gray apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: httpbin-lua
spec:
  workloadSelector:
    labels:
      app: httpbin
  configPatches:
    # The first patch adds the lua filter to the listener/http connection manager
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        portNumber: 8000
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
            subFilter:
              name: "envoy.router"
    patch:
      operation: INSERT_BEFORE
      value: # lua filter specification
       name: envoy.lua
       config:
         inlineCode: |
           function envoy_on_request(request_handle)
             -- Make an HTTP call to an upstream host with the following headers, body, and timeout.
             local headers, body = request_handle:httpCall(
              "lua_cluster",
              {
               [":method"] = "POST",
               [":path"] = "/acl",
               [":authority"] = "internal.org.net"
              },
             "authorize call",
             5000)
           end
EOF
```
