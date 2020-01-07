# 服务网格安全

## 服务可见性控制

```shell
# 调整镜像地址
sed -i '' "s/docker.io\/kennethreitz/registry.sloth.com\/ipaas/g" istio-release/samples/httpbin/httpbin.yaml
sed -i '' "s/governmentpaas/registry.sloth.com\/ipaas/g" istio-release/samples/sleep/sleep.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-sec1
 labels:
    istio-injection: enabled
EOF
kubectl -n samples-sec1 apply -f istio-release/samples/sleep/sleep.yaml

export SOURCE_POD=$(kubectl -n samples-sec1 get pod -l app=sleep -o jsonpath={.items..metadata.name})

kubectl -n samples-sec1 logs -f $SOURCE_POD istio-proxy
```

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: samples-sec2
 labels:
    istio-injection: enabled
EOF
kubectl -n samples-sec2 apply -f istio-release/samples/httpbin/httpbin.yaml

kubectl -n samples-sec1 exec -it $SOURCE_POD -c sleep -- curl -i http://httpbin.samples-sec2:8000/ip

kubectl -n samples-sec2 patch svc httpbin -p "{\"metadata\":{\"annotations\":{\"networking.istio.io/exportTo\":\"*\"}}}"
kubectl -n samples-sec1 exec -it $SOURCE_POD -c sleep -- curl -i http://httpbin.samples-sec2:8000/ip

kubectl -n samples-sec2 patch svc httpbin -p "{\"metadata\":{\"annotations\":{\"networking.istio.io/exportTo\":\".\"}}}"
kubectl -n samples-sec1 exec -it $SOURCE_POD -c sleep -- curl -i http://httpbin.samples-sec2:8000/ip


## 外部服务
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: external-svc
EOF
cat <<EOF | kubectl -n external-svc apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-org
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  resolution: DNS
EOF
kubectl -n samples-sec1 exec -it $SOURCE_POD -c sleep -- curl -i http://httpbin.org/ip

cat <<EOF | kubectl -n samples-sec2 apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        port:
          number: 8000
      weight: 50
    - destination:
        host: httpbin.org
        port:
          number: 80
      weight: 50
EOF
kubectl -n samples-sec1 exec -it $SOURCE_POD -c sleep -- curl -i http://httpbin.samples-sec2:8000/ip
```

```shell
kubectl -n samples-sec2 patch svc httpbin -p "{\"metadata\":{\"annotations\":{\"networking.istio.io/exportTo\":\".\"}}}"

cat <<EOF | kubectl -n samples-sec2 apply -f -
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
  annotations:
    networking.istio.io/exportTo: "."
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
EOF


kubectl -n samples-sec1 exec -it $SOURCE_POD -c sleep -- curl -i http://httpbin.samples-sec2:8000/ip
```
