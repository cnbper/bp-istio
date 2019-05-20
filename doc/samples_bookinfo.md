# bookinfo

<https://istio.io/docs/examples/bookinfo/>

```shell
# 创建namespace，并配置自动注入
kubectl create namespace istio-samples
kubectl label namespace istio-samples istio-injection=enabled --overwrite
# 调整镜像地址
sed -i '' "s/istio\/examples-bookinfo/registry.sloth.com\/istio\/examples-bookinfo/g" istio-release/samples/bookinfo/platform/kube/bookinfo.yaml
# 安装
kubectl -n istio-samples apply -f istio-release/samples/bookinfo/platform/kube/bookinfo.yaml

# 测试
kubectl -n istio-samples get services
kubectl -n istio-samples get pods
kubectl -n istio-samples exec -it $(kubectl -n istio-samples get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
```

## 定义入口网关配置

```shell
# 添加以下内容
#     - uri:
#        prefix: /static
kubectl -n istio-samples apply -f istio-release/samples/bookinfo/networking/bookinfo-gateway.yaml

# 测试
kubectl get Gateway -n istio-samples
kubectl get VirtualService -n istio-samples
# 确定 ingress port 31380
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
curl -s http://172.17.8.101:31380/productpage | grep -o "<title>.*</title>"
```

## 清除数据

```shell
kubectl -n istio-samples delete -f istio-release/samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl -n istio-samples delete -f istio-release/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete namespace istio-samples
```