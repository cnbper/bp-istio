# istio-proxy

```shell
# 查看 istio-proxy 日志
kubectl -n istio-samples get pod
kubectl -n istio-samples logs -f reviews-v2-95f489c6b-fwds8 istio-proxy

# 进入 istio-proxy
kubectl -n istio-samples exec -it reviews-v2-95f489c6b-fwds8 -c istio-proxy sh
```

## harbor.sit.cmft.com/istio/proxy_init:1.1.3