# samples

```shell
# 调整镜像地址
sed -i '' "s/docker.io\/kennethreitz/registry.sloth.com\/ipaas/g" istio-release/samples/httpbin/httpbin.yaml
sed -i '' "s/governmentpaas/registry.sloth.com\/ipaas/g" istio-release/samples/sleep/sleep.yaml
```

## samples-1

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples
 labels:
    istio-injection: enabled
EOF

kubectl -n samples apply -f istio-release/samples/httpbin/httpbin.yaml
kubectl -n samples apply -f istio-release/samples/sleep/sleep.yaml

# 查看日志
kubectl -n samples logs -f $(kubectl -n samples get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy

kubectl -n samples exec $(kubectl -n samples get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin.samples:8000/ip
# -L参数会让 HTTP 请求跟随服务器的重定向。curl 默认不跟随重定向。
# -s参数将不输出错误和进度信息。
# -o参数将服务器的回应保存成文件，等同于wget命令。
```

```shell
cat <<EOF | kubectl -n samples apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: httpbin
spec:`
  rules:
  - host: httpbin.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: httpbin
          servicePort: http
EOF

# 访问：http://httpbin.sloth.com
```

## samples-header

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples
 labels:
    istio-injection: enabled
EOF
kubectl -n samples apply -f /Users/zhangbaohao/repository/git.dev.cmrh.com/cmf-paas/cmf-paas-example/cmf-paas-sequence-boot-example/script/kubernetes/sequence-server.yaml

# 查看日志
kubectl -n samples logs -f $(kubectl -n samples get pod -l app=sequence-server -o jsonpath={.items..metadata.name}) -c sequence-server
kubectl -n samples logs -f $(kubectl -n samples get pod -l app=sequence-server -o jsonpath={.items..metadata.name}) -c istio-proxy

# 部署 sleep
kubectl apply -f istio-release/samples/sleep/sleep.yaml

# 测试
kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - -H 'data: 12131' http://sequence-server.samples:8080/api/sequence

# 用例1：网格内微服务不支持过长Header，直接访问此服务时
# [sidecar-proxy-access] [2020-01-05T13:54:48.486Z] "GET /api/sequence HTTP/1.1" 400 - "-" "-" 0 800 73 72 "-" "curl/7.64.0" "0c5e9634-37b6-46a9-8357-9550e02237e2" "sequence-server.samples:8080" "127.0.0.1:8080" inbound|8080|http|sequence-server.samples.svc.cluster.local - 10.244.2.9:8080 10.244.1.9:56824 "-"

# 用例3：构造过长Header访问网关
# 直接大header访问网关： 494 Request Header Or Cookie Too Large
# 资料：494 - 请求头太大（Nginx）。Nginx内置代码和431类似，但是是被更早地引入在版本0.9.4（在2011年1月21日）。

# 用例3:
# 网关解析token，下传过大header 431 Request Header Fields Too Large
# [sidecar-proxy-access] [2020-01-03T09:04:46.721Z] "- - HTTP/1.1" 0 DC "-" "-" 0 0 2 - "-" "-" "-" "-" "-" - - 10.244.12.207:8080 10.244.5.87:39870 "-"
# 资料：431 - 请求头部字段太大。服务器由于一个单独的请求头部字段或者是全部的字段太大而不愿意处理请求。
# 网关首先建立连接，发现头部过大，放弃向后传递，关闭连接

# 需确认是否为网关问题
# 部署demo，通过网关访问demo
```

## samples-2

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-1
 labels:
    istio-injection: enabled
EOF
kubectl -n samples-1 apply -f istio-release/samples/httpbin/httpbin.yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-2
 labels:
    istio-injection: enabled
EOF
kubectl -n samples-2 apply -f istio-release/samples/sleep/sleep.yaml

cat <<EOF | kubectl -n samples-1 apply -f -
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

kubectl -n samples-2 exec $(kubectl -n samples-2 get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin.samples-1:8000/ip

kubectl delete ns samples-1 samples-2
```

- 访问：<http://httpbin.sloth.com>

- 限制服务可见性

```shell
kubectl -n istio-system get configmap istio -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -

# 测试
istioctl -n samples-2 proxy-config clusters sleep-6ff9df6ddf-j6trf | grep httpbin
kubectl -n samples-2 exec $(kubectl -n samples-2 get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin.samples-1:8000/ip
curl http://httpbin.sloth.com/

# case 1
# networking.istio.io/exportTo: "."
kubectl -n samples-1 apply -f istio-release/samples/httpbin/httpbin.yaml

# case 2
cat <<EOF | kubectl -n samples-2 apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
spec:
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
EOF
cat <<EOF | kubectl -n samples-2 apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
spec:
  outboundTrafficPolicy:
    mode: ALLOW_ANY
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
EOF

# case 3
cat <<EOF | kubectl -n samples-1 apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
spec:
  ingress:
  - port:
      number: 8001
      protocol: HTTP
      name: somename
    defaultEndpoint: unix:///var/run/someuds.sock
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
EOF




cat <<EOF | kubectl -n samples-1 apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: default
spec:
  hosts: httpbin.samples-1
  exportTo:
  - "."
  trafficPolicy:
    tls:
      mode: DISABLE
EOF


```

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
  - match:
    - headers:
        role:
          exact: gray1
    route:
    - destination:
        host: httpbin-v2
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
