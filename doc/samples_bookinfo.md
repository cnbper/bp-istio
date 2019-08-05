# bookinfo

<https://istio.io/docs/examples/bookinfo/>

```shell
# 创建namespace，并配置自动注入
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: istio-samples
 labels:
    istio-injection: enabled
 annotations:
   scheduler.alpha.kubernetes.io/node-selector: istio.data.plane=yes
EOF
# kubectl label namespace istio-samples istio-injection=enabled --overwrite

# 调整镜像地址
sed -i '' "s/docker.io\/istio/registry.sloth.com\/ipaas/g" istio-release/samples/bookinfo/platform/kube/bookinfo.yaml
# 安装
kubectl -n istio-samples apply -f istio-release/samples/bookinfo/platform/kube/bookinfo.yaml

# 测试
kubectl -n istio-samples get services
kubectl -n istio-samples get pods
# 查看 ratings/istio-proxy 日志
kubectl -n istio-samples logs -f \
  $(kubectl -n istio-samples get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
# 查看 productpage/istio-proxy 日志
kubectl -n istio-samples logs -f \
  $(kubectl -n istio-samples get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
# 测试： 在 ratings/ratings 容器在访问 productpage
kubectl -n istio-samples exec -it \
  $(kubectl -n istio-samples get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings \
  -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
```

## 定义入口网关配置

- 配置 ingressgateway

```shell
# 添加以下内容
#     - uri:
#        prefix: /static
kubectl -n istio-samples apply -f istio-release/samples/bookinfo/networking/bookinfo-gateway.yaml

# 测试
kubectl get Gateway -n istio-samples
kubectl get VirtualService -n istio-samples
# 确定 ingress port 31380
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
curl -s http://172.17.8.101:31380/productpage | grep -o "<title>.*</title>"
```

- 配置 ingress

```shell
cat <<EOF | kubectl -n istio-samples apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: bookinfo
spec:
  rules:
  - host: bookinfo.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: productpage
          servicePort: 9080
EOF
# curl -i -X GET --url http://172.17.8.101:32724/productpage --header 'HOST: bookinfo.sloth.com'
```

<http://bookinfo.sloth.com/productpage>

## 权限配置

```shell
cat <<EOF | kubectl -n istio-samples apply -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "productpage"
spec:
  targets:
  - name: productpage
  peers:
  - mtls:
      mode: PERMISSIVE
EOF
```

## 清除数据

```shell
kubectl delete namespace istio-samples
```

## 构建镜像

```shell
docker pull ruby:2.6.3-slim
docker pull python:3.6-slim
docker pull node:12-slim
docker pull gradle:4.8.1
docker pull websphere-liberty:19.0.0.4-javaee8
docker pull mongo
docker pull mysql:8.0.16
```

```shell
cd /Users/zhangbaohao/software/golang/workspace/src/istio.io/istio/samples/bookinfo

./build_push_update_images.sh 1.12.0-dev
```

```shell
cat <<EOF | kubectl -n istio-samples apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reviews-v1
  labels:
    app: reviews
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reviews
      version: v1
  template:
    metadata:
      labels:
        app: reviews
        version: v1
    spec:
      serviceAccountName: bookinfo-reviews
      containers:
      - name: reviews
        env:
        - name: APOLLO_META
          value: "http://192.168.1.102:8080"
        image: registry.sloth.com/ipaas/examples-bookinfo-reviews-v1:1.0-dev
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
EOF

cat <<EOF | kubectl -n istio-samples apply -f -
apiVersion: v1
kind: Service
metadata:
  name: reviews-v1
  labels:
    app: reviews
    service: reviews
spec:
  ports:
  - port: 9080
    name: http
  - port: 9999
    name: http-job
  selector:
    app: reviews
    version: v1
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: reviews-job-v1
spec:
  rules:
  - host: reviews-job-v1.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: reviews-v1
          servicePort: 9999
EOF

kubectl -n istio-samples delete deployment reviews-v1
```
