# istio

<https://istio.io>

## 初始化工作目录

```shell
# 注意调整istio版本
IstioCurVersion=istio-1.1.5
tar zxvf $IstioCurVersion-osx.tar.gz -C temp
mv temp/$IstioCurVersion istio-release
```

## helm安装

### windows

<https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-windows-amd64.zip>

配置环境变量

- D:\software\helm-v2.13.1-windows-amd64

### mac

TODO

## 构建 istio yaml

```shell
# 构建istio init yaml文件
$ helm template --name=istio-init --namespace istio-system --set global.hub=harbor.sit.cmft.com/istio --set certmanager.enabled=true istio-1.1.3/install/kubernetes/helm/istio-init | out-file -filepath istio-init.yaml

# 构建istio yaml文件，注意修改image
$ helm template --name=istio --namespace istio-system --set global.hub=harbor.sit.cmft.com/istio --set prometheus.hub=harbor.sit.cmft.com/prom --set gateways.istio-ingressgateway.type=NodePort istio-1.1.3/install/kubernetes/helm/istio | out-file -filepath istio.yaml

# 获取 Envoy 访问日志
$ helm template --name=istio --namespace=istio-system -x templates/configmap.yaml --set global.proxy.accessLogFile="/dev/stdout" istio-1.1.3/install/kubernetes/helm/istio | out-file -filepath istio-log.yaml
```

## 安装istio

```shell
# 创建namespace
$ kubectl create namespace istio-system

$ kubectl apply -f istio-init.yaml
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

$ kubectl apply -f istio.yaml

# 清除
$ kubectl delete -f istio.yaml
$ kubectl delete -f istio-init.yaml
```

## 安装示例项目

```shell
$ kubectl create namespace istio-samples
# 配置自动注入
$ kubectl label namespace istio-samples istio-injection=enabled --overwrite

# 自动注入
$ kubectl apply -f samples/bookinfo.yaml

# 测试
$ kubectl get services -n istio-samples
$ kubectl get pods -n istio-samples
$ kubectl -n istio-samples exec -it $(kubectl -n istio-samples get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"

# 定义入口网关配置
$ kubectl apply -f samples/bookinfo-gateway.yaml
# 测试
$ kubectl get gateway
$ curl -s http://100.69.218.7:31380/productpage | grep -o "<title>.*</title>"
# http://100.69.216.105:8080/productpage

# 清除
$ kubectl delete -f samples/bookinfo-gateway.yaml
$ kubectl delete -f samples/bookinfo.yaml
$ kubectl delete namespace istio-samples
```

## 规则配置

```shell
# 初始化
$ kubectl apply -f samples/destination-rule-all.yaml
$ kubectl delete -f samples/destination-rule-all.yaml

$ kubectl apply -f samples/virtual-service-all-v1.yaml
$ kubectl delete -f samples/virtual-service-all-v1.yaml

$ kubectl apply -f samples/fault-injection-details-v1.yaml
$ kubectl delete -f samples/fault-injection-details-v1.yaml

$ kubectl apply -f samples/virtual-service-ratings-test-delay.yaml
$ kubectl delete -f samples/virtual-service-ratings-test-delay.yaml

$ kubectl apply -f samples/virtual-service-ratings-test-abort.yaml
$ kubectl delete -f samples/virtual-service-ratings-test-abort.yaml

$ kubectl apply -f samples/fault-injection-productpage-v1.yaml
$ kubectl delete -f samples/fault-injection-productpage-v1.yaml

```