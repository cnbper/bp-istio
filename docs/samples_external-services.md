# Accessing External Services

<https://istio.io/docs/tasks/traffic-management/egress/egress-control/>

```shell
# 调整镜像地址
sed -i '' "s/docker.io\/kennethreitz/registry.sloth.com\/ipaas/g" istio-release/samples/httpbin/httpbin.yaml
sed -i '' "s/governmentpaas/registry.sloth.com\/ipaas/g" istio-release/samples/sleep/sleep.yaml

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

## ALLOW_ANY

```shell
kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: ALLOW_ANY"

kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | kubectl replace -n istio-system -f -

# 等待下发成功后
kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com
kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I http://httpbin.org/headers
# kubectl -n istio-samples logs -f $SOURCE_POD istio-proxy
```

## REGISTRY_ONLY

```shell
kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: REGISTRY_ONLY"

kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -

# 等待下发成功后
kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com
kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I http://httpbin.org/headers
# kubectl -n istio-samples logs -f $SOURCE_POD istio-proxy
```

### http

```shell
# 建立 Service Entry 对象，注册外部服务
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin.org
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
EOF

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I http://httpbin.org/headers
# kubectl delete se httpbin.org
```

### https

```shell
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: edition.cnn.com
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

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com
# kubectl delete se edition.cnn.com
```

## 外部服务治理

### 超时控制

```shell
kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin.org
spec:
  hosts:
    - httpbin.org
  http:
  - timeout: 3s
    route:
      - destination:
          host: httpbin.org
        weight: 100
EOF

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
```

### http -> https

```shell
kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I http://edition.cnn.com
kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: edition.cnn.com
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 443
    name: http-443
    protocol: HTTP
  - number: 80
    name: http-80
    protocol: HTTP
  - number: 8080
    name: http-8080
    protocol: HTTP
  resolution: DNS
EOF

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I http://edition.cnn.com

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: edition.cnn.com
spec:
  host: edition.cnn.com
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: SIMPLE
EOF

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I http://edition.cnn.com:443

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: edition.cnn.com
spec:
  hosts:
  - edition.cnn.com
  http:
  - match:
    - port: 8080
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 80
EOF

kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I http://edition.cnn.com:8080
```
