# egress

<https://istio.io/docs/tasks/traffic-management/egress>

```shell
sed -i '' "s/pstauffer\/curl/registry.sloth.com\/ipaas\/curl/g" istio-release/samples/sleep/sleep.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: istio-samples
 labels:
    istio-injection: enabled
EOF

kubectl -n istio-samples apply -f istio-release/samples/sleep/sleep.yaml

export SOURCE_POD=$(kubectl -n istio-samples get pod -l app=sleep -o jsonpath={.items..metadata.name})
```









### http -> https

```shell
kubectl apply -f - <<EOF
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
EOF

kubectl apply -f - <<EOF
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

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
```

### 清除数据

```shell
kubectl delete DestinationRule edition-cnn-com
kubectl delete VirtualService edition-cnn-com
kubectl delete VirtualService httpbin-org
kubectl delete ServiceEntry edition-cnn-com
kubectl delete ServiceEntry httpbin-org
```

## egressgateway

<https://istio.io/docs/reference/config/installation-options/>

```shell
# 构建yaml文件
LocalHub=registry.sloth.com/ipaas

helm template --name istio-egressgateway --namespace istio-system \
    -x charts/gateways/templates/deployment.yaml \
    -x charts/gateways/templates/service.yaml \
    -x charts/gateways/templates/serviceaccount.yaml \
    -x charts/gateways/templates/autoscale.yaml \
    -x charts/gateways/templates/role.yaml \
    -x charts/gateways/templates/rolebindings.yaml \
    --set global.hub=$LocalHub \
    --set gateways.istio-ingressgateway.enabled=false \
    --set gateways.istio-egressgateway.enabled=true \
    istio-release/install/kubernetes/helm/istio > yaml/istio-egressgateway.yaml

kubectl apply -f yaml/istio-egressgateway.yaml

kubectl get pod -l istio=egressgateway -n istio-system
```

### http & https

```shell
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: edition-cnn-com
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
EOF

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics

# 将服务绑定到 egressgateway
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - edition.cnn.com
  - port:
      number: 443
      name: tls
      protocol: TLS
    hosts:
    - edition.cnn.com
    tls:
      mode: PASSTHROUGH
EOF
```

```shell
# 配置路由规则，将网格请求引导到服务网关
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: edition-cnn-com
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 80
      weight: 100
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sni_hosts:
      - edition.cnn.com
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        port:
          number: 443
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
      sni_hosts:
      - edition.cnn.com
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
      weight: 100
EOF

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics

kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
```

- http -> https

```shell
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: edition-cnn-com
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
      weight: 100
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
        mode: SIMPLE # initiates HTTPS for connections to edition.cnn.com
EOF

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics

kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
```

### 清除数据

```shell
kubectl delete serviceentry edition-cnn-com
kubectl delete gateway istio-egressgateway
kubectl delete virtualservice edition-cnn-com
kubectl delete destinationrule edition-cnn-com
```
