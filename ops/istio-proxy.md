# istio-proxy

```shell

# http://100.69.216.105:8080/productpage
# http://100.69.218.7:31380/productpage

curl -i -X GET --url http://100.69.218.4:30131/ --header 'HOST: echo.com'
curl -i -X GET --url http://100.69.218.4:30131/productpage --header 'HOST: echo.com'

kubectl get pod -n kong
kubectl -n kong logs -f kong-b89445bb-lfdtk istio-proxy
kubectl -n kong exec -it kong-b89445bb-lfdtk -c kong-proxy sh
```

## harbor.sit.cmft.com/istio/proxy_init:1.1.3