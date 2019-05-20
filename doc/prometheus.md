# prometheus

```shell
kubectl -n istio-system get svc prometheus

curl http://172.17.8.101:31380/productpage

kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090
```

http://localhost:9090/graph

在网页顶部的 “Expression” 输入框中，输入文本, 然后，单击 Execute 按钮

- istio_requests_total
- 对 productpage 服务的所有请求的总数 istio_requests_total{destination_service="productpage.istio-samples.svc.cluster.local"}
- 对 reviews 服务的 v3 的所有请求的总数 istio_requests_total{destination_service="reviews.istio-samples.svc.cluster.local", destination_version="v3"}
- 过去 5 分钟内对所有 productpage 服务的请求率 rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])

## 配置

1 参考 istio-auth.yaml 中 prometheus 相关配置

2 参考 grafana.yaml 配置
