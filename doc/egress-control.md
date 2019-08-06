# egress

```shell

sed -i '' "s/pstauffer\/curl/registry.sloth.com\/ipaas\/curl/g" istio-release/samples/sleep/sleep.yaml
kubectl -n istio-samples apply -f istio-release/samples/sleep/sleep.yaml

# ALLOW_ANY (默认)
kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | kubectl replace -n istio-system -f -

kubectl -n istio-samples exec -it sleep-8567f685c4-qjc9w -c sleep -- curl -I https://edition.cnn.com


# REGISTRY_ONLY
kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -

kubectl -n istio-samples exec -it sleep-8567f685c4-qjc9w -c sleep -- curl -I https://edition.cnn.com

kubectl -n istio-samples apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: edition-cnn-com
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  location: MESH_EXTERNAL
EOF

kubectl -n istio-samples exec -it sleep-8567f685c4-qjc9w -c sleep -- curl -I https://edition.cnn.com

kubectl -n istio-samples logs sleep-8567f685c4-qjc9w -c istio-proxy
# kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'edition.cnn.com'
```

## http -> https

```shell
kubectl -n istio-samples apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: edition-cnn-com
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  - number: 443
    name: http-port-for-tls-origination
    protocol: HTTP
  resolution: DNS
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: edition-cnn-com
spec:
  hosts:
  - edition.cnn.com
  http:
  - match:
    - port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: edition-cnn-com
spec:
  host: edition.cnn.com
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: SIMPLE # initiates HTTPS when accessing edition.cnn.com
EOF

kubectl -n istio-samples exec -it sleep-8567f685c4-qjc9w -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics

```


```shell
kubectl -n istio-samples exec -it sleep-8567f685c4-qjc9w -c sleep -- curl -I https://172.20.10.2/app -X POST -H 'Host:nginx.sloth.com' --insecure
```
