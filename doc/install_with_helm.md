# Istio

<https://istio.io/docs/setup/kubernetes/install/helm/>
<https://istio.io/docs/reference/config/installation-options/>

## istio init

```shell
# 构建yaml文件
LocalHub=registry.sloth.com

# yaml/istio-init.yaml
## mac linux
helm template --name=istio-init --namespace istio-system \
  --set global.hub=$LocalHub/istio \
  --set certmanager.enabled=true \
  istio-release/install/kubernetes/helm/istio-init > yaml/istio-init.yaml
## win
helm template --name=istio-init --namespace istio-system --set global.hub=$LocalHub/istio --set certmanager.enabled=true istio-release/install/kubernetes/helm/istio-init | out-file -filepath yaml/istio-init.yaml

# yaml/istio.yaml
helm template --name=istio --namespace istio-system \
  --set global.hub=$LocalHub/istio \
  --set global.tracer.zipkin.address="zipkin.zipkin-system:9411" \
  --set prometheus.hub=$LocalHub/prom \
  --set gateways.istio-ingressgateway.type=NodePort \
  --set global.proxy.accessLogFile="/dev/stdout" \
  istio-release/install/kubernetes/helm/istio > yaml/istio.yaml

# yaml/istio-auth.yaml
helm template --name=istio --namespace istio-system \
  --set global.hub=$LocalHub/istio \
  --set global.tracer.zipkin.address="zipkin.zipkin-system:9411" \
  --set prometheus.hub=$LocalHub/prom \
  --set gateways.istio-ingressgateway.type=NodePort \
  --set global.proxy.accessLogFile="/dev/stdout" \
  --set global.mtls.enabled=true \
  --set global.controlPlaneSecurityEnabled=true \
  istio-release/install/kubernetes/helm/istio > yaml/istio-auth.yaml

# yaml/istio-auth-noprom.yaml
helm template --name=istio --namespace istio-system \
  --set global.hub=$LocalHub/istio \
  --set global.tracer.zipkin.address="zipkin.zipkin-system:9411" \
  --set prometheus.enabled=false \
  --set gateways.istio-ingressgateway.type=NodePort \
  --set global.proxy.accessLogFile="/dev/stdout" \
  --set global.mtls.enabled=true \
  --set global.controlPlaneSecurityEnabled=true \
  istio-release/install/kubernetes/helm/istio > yaml/istio-auth-noprom.yaml

# yaml/istio-kiali.yaml
helm template --name=istio --namespace istio-system \
  --set global.enableHelmTest=false \
  --set hub=$LocalHub/kiali \
  istio-release/install/kubernetes/helm/istio/charts/kiali > yaml/istio-kiali.yaml

# yaml/istio-servicegraph.yaml
helm template --name=istio --namespace istio-system \
  --set global.hub=$LocalHub/istio \
  istio-release/install/kubernetes/helm/istio/charts/servicegraph > yaml/istio-servicegraph.yaml

# yaml/istio-grafana.yaml
helm template --name=istio --namespace istio-system \
  --set global.enableHelmTest=false \
  --set grafana.image.repository=$LocalHub/grafana/grafana \
  istio-release/install/kubernetes/helm/istio/charts/grafana > yaml/istio-grafana.yaml
```

```shell
# 安装
kubectl create namespace istio-system
kubectl apply -f yaml/istio-init.yaml

# 验证
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

# 卸载
kubectl delete -f yaml/istio-init.yaml
kubectl delete namespace istio-system
# Deleting CRDs and Istio Configuration
kubectl delete -f istio-release/install/kubernetes/helm/istio-init/files
```

## 部署 Istio defalut

```shell
# 安装
kubectl apply -f yaml/istio-auth-noprom.yaml

# 验证
kubectl get svc -n istio-system -o wide
kubectl get pods -n istio-system -o wide

# 卸载
kubectl delete -f yaml/istio-auth-noprom.yaml
```
