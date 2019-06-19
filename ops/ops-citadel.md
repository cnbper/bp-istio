# 修复 Citadel

<https://istio.io/zh/help/ops/security/repairing-citadel/>

## 验证 istio-citadel pod 的状态

```shell
kubectl -n istio-system get pod -l istio=citadel
```

- 如果 istio-citadel pod 不存在，请尝试重新部署 pod
- 如果 istio-citadel pod 存在但其状态不是 Running ，请运行以下命令以获得更多 调试信息并检查是否有任何错误：

```shell
kubectl -n istio-system logs -l istio=citadel
kubectl -n istio-system describe pod -l istio=citadel
```
