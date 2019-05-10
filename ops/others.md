# others

```shell
# 获取 istio-pilot 的 ClusterIP
kubectl -n istio-system get svc istio-pilot -o jsonpath='{.spec.clusterIP}'

# 查看 eds
curl http://10.109.236.42:8080/debug/edsz|grep "outbound|9080||productpage.istio-samples.svc.cluster.local" -A 27 -B 1

# 从这里可以看出，各个微服务之间是直接通过 PodIP + Port 来通信的，Service 只是做一个逻辑关联用来定位 Pod，实际通信的时候并没有通过 Service。
```