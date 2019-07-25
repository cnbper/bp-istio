# 限制服务可见性

```shell
cat <<EOF | kubectl -n istio-samples apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
spec:
  hosts:
  - productpage
  exportTo:
  - "."
  http:
  - route:
    - destination:
        host: productpage
        subset: v1
EOF
```

```shell
cat <<EOF | kubectl -n istio-samples apply -f -
apiVersion: v1
kind: Service
metadata:
  name: productpage
  labels:
    app: productpage
    service: productpage
  annotations:
    networking.istio.io/exportTo: "."
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: productpage
EOF
```

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: istio-demo
 labels:
    istio-injection: enabled
EOF

sed -i '' "s/pstauffer\/curl/registry.sloth.com\/pstauffer\/curl/g" istio-release/samples/sleep/sleep.yaml

kubectl -n istio-demo apply -f istio-release/samples/sleep/sleep.yaml

kubectl exec $(kubectl get pod -l app=sleep -n istio-demo -o jsonpath={.items..metadata.name}) -c sleep -n istio-demo -- curl http://productpage.istio-samples:9080/productpage
```
