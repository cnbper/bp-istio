# istio-pilot

- pilot-agent
- pilot-discovery
- sidecar-injector

```shell
# 查看 Pilot 日志
kubectl -n istio-system logs $(kubectl -n istio-system get pods -l app=pilot -o jsonpath='{.items[0].metadata.name}') --follow --tail=100 discovery

# 进入pilot容器
kubectl -n istio-system exec -it $(kubectl -n istio-system get pods -l app=pilot -o jsonpath='{.items[0].metadata.name}') /bin/sh

# 查看 pilot-discovery 启动信息
ps -f -w -w -p1

/usr/local/bin/pilot-discovery discovery --monitoringAddr=:15014 --log_output_level=default:info --domain cluster.local --keepaliveMaxServerConnectionAge 30m
```