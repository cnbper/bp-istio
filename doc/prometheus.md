# prometheus

## 手动安装

```shell
cd /Users/zhangbaohao/repository/github.com/cnbper/kubernetes-vagrant-centos-cluster/tools/prometheus
tar zxvf prometheus-2.3.1.linux-amd64.tar.gz

# 配置环境变量
export PATH=/Users/zhangbaohao/repository/github.com/cnbper/kubernetes-vagrant-centos-cluster/tools/prometheus/prometheus-2.3.1.linux-amd64/prometheus

# 启动
prometheus --config.file=prometheus.yml

http://172.17.8.101:9090/graph
http://172.17.8.101:9090/config

# 重新加载配置文件
curl -i -X POST http://172.17.8.101:9090/-/reload
```

## kub

## 安装

```shell
# yaml/istio-prometheus.yaml
helm template --name=istio --namespace istio-system \
  --values istio-release/install/kubernetes/helm/istio/values.yaml \
  --set hub=$LocalHub/prom \
  istio-release/install/kubernetes/helm/istio/charts/prometheus > yaml/istio-prometheus.yaml

kubectl apply -f yaml/istio-prometheus.yaml

kubectl delete -f yaml/istio-prometheus.yaml
```

```shell
kubectl -n istio-system get svc prometheus
kubectl -n istio-system get pod -l app=prometheus

curl http://172.17.8.101:31380/productpage

kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090
```

http://localhost:9090/graph

在网页顶部的 “Expression” 输入框中，输入文本, 然后，单击 Execute 按钮

- istio_requests_total
- 对 productpage 服务的所有请求的总数 istio_requests_total{destination_service="productpage.istio-samples.svc.cluster.local"}
- 对 reviews 服务的 v3 的所有请求的总数 istio_requests_total{destination_service="reviews.istio-samples.svc.cluster.local", destination_version="v3"}
- 过去 5 分钟内对所有 productpage 服务的请求率 rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])
