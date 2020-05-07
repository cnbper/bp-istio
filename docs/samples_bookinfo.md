# samples bookinfo

<https://istio.io/docs/examples/bookinfo/>

## 准备工作

```shell
# 调整镜像地址
sed -i '' "s/docker.io\/istio/registry.sloth.com\/ipaas/g" istio-release/samples/bookinfo/platform/kube/bookinfo.yaml
sed -i '' "s/docker.io\/istio/registry.sloth.com\/ipaas/g" istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml
sed -i '' "s/docker.io\/istio/registry.sloth.com\/ipaas/g" istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml
sed -i '' "s/docker.io\/istio/registry.sloth.com\/ipaas/g" istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
# 调整镜像版本
# sed -i '' "s/1.15.0/1.12.0/g"
```

## 测试

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-bookinfo
 labels:
    istio-injection: enabled
EOF
# kubectl label namespace samples-bookinfo istio-injection=enabled --overwrite

# 安装
kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/networking/destination-rule-all.yaml

# 测试
kubectl -n samples-bookinfo get services
kubectl -n samples-bookinfo get pods
# 查看 ratings/istio-proxy 日志
kubectl -n samples-bookinfo logs -f \
  $(kubectl -n samples-bookinfo get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
# 查看 productpage/istio-proxy 日志
kubectl -n samples-bookinfo logs -f \
  $(kubectl -n samples-bookinfo get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
# 测试： 在 ratings/ratings 容器在访问 productpage
kubectl -n samples-bookinfo exec -it \
  $(kubectl -n samples-bookinfo get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings \
  -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
```

## 定义入口网关配置

- 配置 ingressgateway

```shell
# 添加以下内容
#     - uri:
#        prefix: /static
kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/networking/bookinfo-gateway.yaml

# 测试
kubectl -n samples-bookinfo get Gateway
kubectl -n samples-bookinfo get VirtualService
# 确定 ingress port 31380
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
curl -s http://172.17.8.101:31380/productpage | grep -o "<title>.*</title>"
```

- 配置 ingress

```shell
cat <<EOF | kubectl -n samples-bookinfo apply -f -
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

# <http://bookinfo.sloth.com/productpage>
```

## 测试 mysql

- 初始化数据库 <https://github.com/istio/istio/blob/master/samples/bookinfo/src/mysql/mysqldb-init.sql>

```sql
# Initialize a mysql db with a 'test' db and be able test productpage with it.
# mysql -h 127.0.0.1 -ppassword < mysqldb-init.sql

CREATE DATABASE test;
USE test;

CREATE TABLE `ratings` (
  `ReviewID` INT NOT NULL,
  `Rating` INT,
  PRIMARY KEY (`ReviewID`)
);
INSERT INTO ratings (ReviewID, Rating) VALUES (1, 5);
INSERT INTO ratings (ReviewID, Rating) VALUES (2, 4);
```

```shell
/usr/local/mysql/bin/mysql -h 127.0.0.1 -psloth@linux < mysqldb-init.sql

/usr/local/mysql/bin/mysql -h 127.0.0.1 -psloth@linux test -e "select * from ratings;"

/usr/local/mysql/bin/mysql -h 127.0.0.1 -psloth@linux test -e  "update ratings set rating=1 where reviewid=1;select * from ratings;"
```

- 配置 vm

<https://preliminary.istio.io/zh/docs/examples/virtual-machines/bookinfo/>

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: vm
EOF
istioctl register -n vm mysqldb 172.17.8.150 3306

kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml
kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml

# 清除数据
kubectl -n samples-bookinfo delete -f istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml
kubectl -n samples-bookinfo delete -f istio-release/samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml
```

- 配置 外部服务

```shell
kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml
kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/networking/virtual-service-ratings-mysql.yaml

kubectl -n external-svc apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: mysql.bookinfo
spec:
  hosts:
  - mysql.bookinfo
  addresses:
  - 172.17.8.150/32
  ports:
  - number: 3306
    name: tcp-3306
    protocol: TCP
  location: MESH_EXTERNAL
EOF

# 清除数据
kubectl -n external-svc delete ServiceEntry mysql.bookinfo
kubectl -n samples-bookinfo delete -f istio-release/samples/bookinfo/networking/virtual-service-ratings-mysql.yaml
kubectl -n samples-bookinfo delete -f istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml
```

## 测试 mongodb

```shell
kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
kubectl -n samples-bookinfo apply -f istio-release/samples/bookinfo/networking/virtual-service-ratings-db.yaml

kubectl -n external-svc apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: mongo.bookinfo
spec:
  hosts:
  - mongo.bookinfo
  addresses:
  - 172.17.8.155/32
  ports:
  - number: 27017
    name: mongo-27017
    protocol: MONGO
  location: MESH_EXTERNAL
EOF

# 清除数据
kubectl -n external-svc delete ServiceEntry mongo.bookinfo
kubectl -n samples-bookinfo delete -f istio-release/samples/bookinfo/networking/virtual-service-ratings-db.yaml
kubectl -n samples-bookinfo delete -f istio-release/samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
```

## 权限配置

```shell
cat <<EOF | kubectl -n samples-bookinfo apply -f -
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
kubectl delete namespace samples-bookinfo
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
cat <<EOF | kubectl -n samples-bookinfo apply -f -
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

cat <<EOF | kubectl -n samples-bookinfo apply -f -
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

kubectl -n samples-bookinfo delete deployment reviews-v1
```
