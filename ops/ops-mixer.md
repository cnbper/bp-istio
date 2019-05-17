# ops-mixer

```shell
# 查看所有rule
kubectl get rules --all-namespaces
# 获取某个rule信息
kubectl -n istio-system get rules promhttp -o yaml

# HTTP服务访问控制
kubectl apply -f samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml
```