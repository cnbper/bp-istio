# istio 安全

```shell
# 调整镜像地址
sed -i '' "s/docker.io\/kennethreitz/registry.sloth.com\/ipaas/g" istio-release/samples/httpbin/httpbin.yaml
sed -i '' "s/governmentpaas/registry.sloth.com\/ipaas/g" istio-release/samples/sleep/sleep.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-sec1
 labels:
    istio-injection: enabled
EOF
kubectl -n samples-sec1 apply -f istio-release/samples/httpbin/httpbin.yaml
# 查看代理日志
kubectl -n samples-sec1 logs -f $(kubectl -n samples-sec1 get pod -l app=httpbin -o jsonpath={.items..metadata.name}) istio-proxy

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-sec2
 labels:
    istio-injection: enabled
EOF
kubectl -n samples-sec2 apply -f istio-release/samples/sleep/sleep.yaml
# 查看代理日志
kubectl -n samples-sec2 logs -f $(kubectl -n samples-sec2 get pod -l app=sleep -o jsonpath={.items..metadata.name}) istio-proxy

istioctl -n samples-sec2 proxy-config endpoints $(kubectl -n samples-sec2 get pod -l app=sleep -o jsonpath={.items..metadata.name})
istioctl -n samples-sec1 proxy-config endpoints $(kubectl -n samples-sec1 get pod -l app=httpbin -o jsonpath={.items..metadata.name})
```

## 服务可见性控制

```shell
# Sidecar 全局配置，仅允许将流量发送到同一名称空间中的其他工作负载以及istio-system名称空间中的服务。
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
kubectl -n samples-sec2 exec $(kubectl -n samples-sec2 get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -i http://httpbin.samples-sec1:8000/ip

kubectl apply -f istio-release/samples/sleep/sleep.yaml
kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -i http://httpbin.samples-sec1:8000/ip
```

- k8s服务

```yaml
metadata:
  annotations:
    networking.istio.io/exportTo: "."
```

```shell
kubectl -n samples-1 patch svc sleep -p "{\"metadata\":{\"annotations\":{\"networking.istio.io/exportTo\":\".\"}}}"

kubectl -n samples-1 patch svc sleep -p "{\"metadata\":{\"annotations\":{\"networking.istio.io/exportTo\":\"*\"}}}"
```

## mlts
