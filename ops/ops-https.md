# 外部HTTPS服务常见问题解决

```shell
# 调整镜像地址
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
# kubectl -n istio-samples logs -f $SOURCE_POD istio-proxy
```

## 未配置外部服务，访问外部HTTPS服务

```shell
kubectl -n istio-samples exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com

# curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to edition.cnn.com:443
# UF,URX
```

## 配置外部服务 HTTPS，访问外部HTTPS服务

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

# curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to edition.cnn.com:443
# UF,URX
```

## 配置外部服务 HTTP->HTTPS，访问外部HTTPS服务

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
    name: https-443
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
---
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
```

## 503 UH
