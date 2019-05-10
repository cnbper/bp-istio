# Istio

<https://istio.io/docs/setup/kubernetes/install/helm/>
<https://istio.io/docs/reference/config/installation-options/>

## istio init

```shell
IstioCurVersion=istio-1.1.5

rm -rf yaml/istio-init.yaml
helm template --name=istio-init --namespace istio-system \
  --set global.hub=registry.sloth.com/istio \
  --set certmanager.enabled=true \
  $IstioCurVersion/install/kubernetes/helm/istio-init > yaml/istio-init.yaml

# 安装
kubectl create namespace istio-system
kubectl apply -f yaml/istio-init.yaml

# 验证
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

# 卸载
kubectl delete -f yaml/istio-init.yaml
kubectl delete namespace istio-system
# Deleting CRDs and Istio Configuration
kubectl delete -f $IstioCurVersion/install/kubernetes/helm/istio-init/files
```

## 部署 Istio defalut

```shell

rm -rf yaml/istio.yaml
helm template --name=istio --namespace istio-system \
  --set global.hub=registry.sloth.com/istio \
  --set global.tracer.zipkin.address="zipkin.zipkin-system:9411" \
  --set prometheus.hub=registry.sloth.com/prom \
  --set gateways.istio-ingressgateway.type=NodePort \
  --set global.proxy.accessLogFile="/dev/stdout" \
  $IstioCurVersion/install/kubernetes/helm/istio > yaml/istio.yaml
# 修改 image registry.cmft.com/third/busybox:1.30.1

# 安装
kubectl apply -f yaml/istio.yaml

# 验证
kubectl get svc -n istio-system -o wide
kubectl get pods -n istio-system -o wide

# 卸载
kubectl delete -f yaml/istio.yaml
```

## 部署 示例项目

```shell
# 创建namespace，并配置自动注入
kubectl create namespace istio-samples
kubectl label namespace istio-samples istio-injection=enabled --overwrite
# 注意调整镜像地址
kubectl -n istio-samples apply -f $IstioCurVersion/samples/bookinfo/platform/kube/bookinfo.yaml
# 测试
kubectl -n istio-samples get services
kubectl -n istio-samples get pods
kubectl -n istio-samples exec -it $(kubectl -n istio-samples get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"

# 确定 ingress port 31380
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'

# 定义入口网关配置，注意调整命名空间
kubectl -n istio-samples apply -f $IstioCurVersion/samples/bookinfo/networking/bookinfo-gateway.yaml
# 测试
kubectl get Gateway -n istio-samples
kubectl get VirtualService -n istio-samples
curl -s http://172.17.8.101:31380/productpage | grep -o "<title>.*</title>"

# 卸载
kubectl -n istio-samples delete -f $IstioCurVersion/samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl -n istio-samples delete -f $IstioCurVersion/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete namespace istio-samples
```

```shell
# 注意调整命名空间
# init
$ kubectl -n istio-samples apply -f $IstioCurVersion/samples/bookinfo/networking/destination-rule-all.yaml
$ kubectl -n istio-samples get DestinationRule
# 路由调整
$ kubectl -n istio-samples apply -f $IstioCurVersion/samples/bookinfo/networking/virtual-service-all-v1.yaml
$ kubectl -n istio-samples apply -f $IstioCurVersion/samples/bookinfo/networking/virtual-service-reviews-v2-v3.yaml
# 故障注入
$ kubectl -n istio-samples apply -f $IstioCurVersion/samples/bookinfo/networking/fault-injection-details-v1.yaml
# 故障注入 jason登录
$ kubectl -n istio-samples apply -f $IstioCurVersion/samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml
```