# soft-multitenancy

## 部署多个 Istio 控制面

```shell
$ helm template --name=istio --namespace istio-tenancy \
  --set global.hub=registry.cmft.com/istio \
  --set prometheus.hub=registry.cmft.com/prom \
  --set gateways.istio-ingressgateway.type=NodePort \
  istio-1.1.2/install/kubernetes/helm/istio > istio-tenancy.yaml

# 修改 image registry.cmft.com/third/busybox:1.30.1
# 修改 Service : istio-ingressgateway NodePort端口
## 31380 -> 32380
## 31390 -> 32390
## 31400 -> 32400
# 移动 MutatingWebhookConfiguration : istio-sidecar-injector
## 修改 sidecar-injector.istio.io -> sidecar-injector.tenancy.istio.io
## 修改 istio-injection -> istio-tenancy-injection
# 修改 Deployment : istio-sidecar-injector spec.containers.args
## - --webhookName=sidecar-injector.tenancy.istio.io
# 修改 ValidatingWebhookConfiguration : istio-galley
## 修改 istio-galley ->  istio-tenancy-galley
# 修改 Deployment : istio-galley spec.containers.command
## - --webhook-name=istio-tenancy-galley

# 安装通用组件
$ kubectl apply -f istio-multitenancy.yaml
$ kubectl --context=cluster1 get mutatingwebhookconfiguration

# 安装
$ kubectl --context=cluster1 create ns istio-tenancy
$ kubectl --context=cluster1 apply -f istio-tenancy.yaml

# 验证
$ kubectl --context=cluster1 -n istio-tenancy get po -o wide
$ kubectl --context=cluster1 -n istio-tenancy get svc -o wide

# 进入pod
$ kubectl --context=cluster1 -n istio-tenancy get po istio-sidecar-injector-6f58659974-pq98v -o yaml
$ kubectl --context=cluster1 -n istio-tenancy logs -f istio-sidecar-injector-6f58659974-pq98v
$ kubectl --context=cluster1 -n istio-tenancy exec -it istio-sidecar-injector-6f58659974-pq98v -- /bin/bash

# 卸载
$ kubectl --context=cluster1 delete -f istio-tenancy.yaml
$ kubectl --context=cluster1 delete ns istio-tenancy
```

## 配置租户管理员

```shell
# 验证
$ kubectl --context=cluster1-tenancy get po -n istio-tenancy
```

## 关注特定命名空间进行服务发现

```shell
# 创建namespace，并配置自动注入
$ kubectl create namespace istio-tenancy-samples
$ kubectl label namespace istio-tenancy-samples istio-tenancy-injection=enabled --overwrite
# 自动注入
$ kubectl apply -f samples/bookinfo-tenancy.yaml
# 测试
$ kubectl get services -n istio-tenancy-samples
$ kubectl get pods -n istio-tenancy-samples
$ kubectl -n istio-tenancy-samples exec -it $(kubectl -n istio-tenancy-samples get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"

# 定义入口网关配置
$ kubectl apply -f samples/bookinfo-tenancy-gateway.yaml
# 测试
$ kubectl get gateway -n istio-tenancy-samples
$ curl -s http://172.24.1.133:32380/productpage | grep -o "<title>.*</title>"

# 卸载
$ kubectl delete -f samples/bookinfo-tenancy-gateway.yaml
$ kubectl delete -f samples/bookinfo-tenancy.yaml
$ kubectl delete namespace istio-tenancy-samples
```
