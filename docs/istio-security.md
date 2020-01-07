# istio 安全

## mlts

## 服务可见性控制

- k8s服务

```yaml
metadata:
  annotations:
    networking.istio.io/exportTo: "."
```
