# seata

<http://seata.io/zh-cn/>

## 开发环境配置

- Plugin execution not covered by lifecycle configuration

```shell
# 编辑 lifecycle-mapping-metadata.xml
vi /Users/zhangbaohao/eclipse-workspace/.metadata/.plugins/org.eclipse.m2e.core/lifecycle-mapping-metadata.xml
```

- ${os.detected.classifier}

```xml
<properties>
    <os.detected.classifier>osx-x86_64</os.detected.classifier>
</properties>
```

## seata-server

<http://seata.io/zh-cn/docs/user/configurations.html>

- metrics

```conf
## metrics settings
metrics {
  enabled = true
  registry-type = "compact"
  # multi exporters use comma divided
  exporter-list = "prometheus"
  exporter-prometheus-port = 9898
}
```

```shell
netstat -an | grep 9898
netstat -an | grep 8091

http://localhost:9898/metrics
```

## seata-samples

<http://localhost:8084/api/business/purchase/commit>
<http://localhost:8084/api/business/purchase/rollback>

```json
seata_transaction{meter="summary",statistic="count"}
```
