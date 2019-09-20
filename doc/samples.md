# samples

```shell
# 调整镜像地址
sed -i '' "s/docker.io\/kennethreitz/registry.sloth.com\/ipaas/g" istio-release/samples/httpbin/httpbin.yaml
sed -i '' "s/governmentpaas/registry.sloth.com\/ipaas/g" istio-release/samples/sleep/sleep.yaml

kubectl create ns samples
kubectl apply -f <(istioctl kube-inject -f istio-release/samples/httpbin/httpbin.yaml) -n samples
kubectl apply -f <(istioctl kube-inject -f istio-release/samples/sleep/sleep.yaml) -n samples

cat <<EOF | kubectl -n samples apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: httpbin
spec:
  rules:
  - host: httpbin.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: httpbin
          servicePort: http
EOF

kubectl -n samples exec $(kubectl -n samples get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin.samples:8000/ip

kubectl delete ns samples
```

访问：<http://httpbin.sloth.com>

## 灰度测试-1

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples
 labels:
    istio-injection: enabled
EOF

kubectl -n samples apply -f  istio-release/samples/sleep/sleep.yaml

cat <<EOF | kubectl -n samples apply -f -
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
    version: v1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      containers:
      - image: registry.sloth.com/ipaas/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-v2
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
    version: v2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v2
  template:
    metadata:
      labels:
        app: httpbin
        version: v2
    spec:
      containers:
      - image: registry.sloth.com/ipaas/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF

kubectl -n samples exec $(kubectl -n samples get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin.samples:8000/ip

kubectl -n samples exec $(kubectl -n samples get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin-v2.samples:8000/ip

cat <<EOF | kubectl -n samples apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin-route-two-domains
spec:
  hosts:
  - httpbin
  http:
  - route:
    - destination:
        host: httpbin
      weight: 25
    - destination:
        host: httpbin-v2
      weight: 75
EOF

kubectl -n samples exec $(kubectl -n samples get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin.samples:8000/ip
```

## 灰度测试-2

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples2
 labels:
    istio-injection: enabled
EOF

kubectl -n samples2 apply -f  istio-release/samples/sleep/sleep.yaml

kubectl -n samples2 exec $(kubectl -n samples2 get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin.samples:8000/ip
```

## http -> https

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
EOF

kubectl apply -f - <<EOF
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

export SOURCE_POD=$(kubectl -n samples get pod -l app=sleep -o jsonpath={.items..metadata.name})

kubectl -n samples exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics

kubectl -n samples exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com:443/politics

kubectl delete ServiceEntry edition-cnn-com
kubectl delete VirtualService edition-cnn-com
kubectl delete DestinationRule edition-cnn-com
```
