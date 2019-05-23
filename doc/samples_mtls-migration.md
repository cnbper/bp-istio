# 双向 TLS 的迁移

<https://istio.io/docs/tasks/security/mtls-migration/>

本文展示了如何在不中断通信的情况下，把现存 Istio 服务的流量从明文升级为双向 TLS

## 前提条件

- 已成功在 Kubernetes 集群中部署 Istio，并且没有启用双向 TLS 支持

- 初始化数据

```shell
# 注意调整镜像
sed -i '' "s/docker.io/registry.sloth.com/g" istio-release/samples/httpbin/httpbin.yaml
sed -i '' "s/pstauffer/registry.sloth.com\/pstauffer/g" istio-release/samples/sleep/sleep.yaml
# 部署
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f istio-release/samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f istio-release/samples/sleep/sleep.yaml) -n foo
kubectl create ns bar
kubectl apply -f <(istioctl kube-inject -f istio-release/samples/httpbin/httpbin.yaml) -n bar
kubectl apply -f <(istioctl kube-inject -f istio-release/samples/sleep/sleep.yaml) -n bar
kubectl create ns legacy
kubectl apply -f istio-release/samples/sleep/sleep.yaml -n legacy
```

- 检查部署情况：从任意一个命名空间选一个 sleep pod，发送 http 请求到 httpbin.foo。所有的请求都应该能返回 HTTP 200。

```shell
# 检查部署情况
for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
```

- 确认系统中不存在认证策略和目标规则

```shell
# 确认系统中不存在认证策略和目标规则（mixer相关除外）
kubectl get policies.authentication.istio.io --all-namespaces
kubectl get destinationrule --all-namespaces
```

## 配置客户端进行双向 TLS 通信

利用设置 DestinationRule 的方式，让 Istio 服务进行双向 TLS 通信。

```shell
cat <<EOF | kubectl apply -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "example-httpbin-istio-client-mtls"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```

sleep.foo 和 sleep.bar 就会开始使用双向 TLS 和 httpbin.foo 进行通信了。而 sleep.legacy 因为没有进行 sidecar 注入，因此不受 DestinationRule 配置影响，还是会使用明文和 httpbin.foo 通信。

现在复查一下，所有到 httpbin.foo 的通信是否依旧成功：

```shell
for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
```

还可以在 DestinationRule 中指定一个客户端的子集所发出的请求来是用双向 TLS 通信，然后使用 Grafana 验证配置执行情况，确认通过之后，将策略的应用范围扩大到该服务的所有子集。

## 锁定使用双向 TLS

把所有进行过 sidecar 注入的客户端到服务器流量都迁移到双向 TLS 之后，就可以设置 httpbin.foo 只支持双向 TLS 流量了。

```shell
cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-httpbin-permissive"
  namespace: foo
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
      mode: STRICT
EOF
```

这样设置之后，sleep.legacy 的请求就会失败。

```shell
for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
```

也就是说，如果不能把所有服务都迁移到 Istio (进行 Sidecar 注入)的话，就只能使用 PERMISSIVE 模式了。然而在配置为 PERMISSIVE 的时候，是不会对明文流量进行授权和鉴权方面的检查的。我们推荐使用 RBAC 来给不同的路径配置不同的授权策略。

## 清除数据

```shell
# 清除数据
kubectl delete ns foo bar legacy
```
