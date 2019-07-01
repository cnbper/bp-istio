# Istio

<https://istio.io/docs/setup/kubernetes/install/helm/>
<https://istio.io/docs/reference/config/installation-options/>

## istio init

- **构建安装文件**

```shell
# 构建yaml文件
LocalHub=registry.sloth.com/ipaas

# yaml/istio-init.yaml
helm template --name=istio-init --namespace istio-system \
  --set global.hub=$LocalHub \
  --set certmanager.enabled=true \
  istio-release/install/kubernetes/helm/istio-init > yaml/istio-init.yaml
```

- **安装crd**

```shell
# 安装
kubectl label nodes kube-node1 istio.control.plane=yes
kubectl label nodes kube-node2 istio.control.plane=yes
kubectl label nodes kube-node1 istio.data.plane=yes
kubectl label nodes kube-node2 istio.data.plane=yes

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: istio-system
 annotations:
   scheduler.alpha.kubernetes.io/node-selector: istio.control.plane=yes
EOF

kubectl apply -f yaml/istio-init.yaml

# 验证 28
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

# 删除无用安装文件
kubectl delete -f yaml/istio-init.yaml
```

- **卸载**

```shell
# 卸载
kubectl delete namespace istio-system
kubectl delete -f istio-release/install/kubernetes/helm/istio-init/files
```

## istio控制面

- **构建istio控制面安装文件**

```shell
# 构建yaml文件
LocalHub=registry.sloth.com/ipaas

# 最小安装
helm template --name=istio --namespace istio-system \
  --set global.hub=$LocalHub \
  --set global.tracer.zipkin.address="zipkin.istio-system:9411" \
  --set global.proxy.accessLogFile="/dev/stdout" \
  --set global.proxy.resources.requests.cpu=50m \
  --set global.proxy.resources.requests.memory=64Mi \
  --set pilot.resources.requests.cpu=62m \
  --set pilot.resources.requests.memory=256Mi \
  --set mixer.telemetry.resources.requests.cpu=125m \
  --set mixer.telemetry.resources.requests.memory=128Mi \
  --set gateways.enabled=false \
  --set prometheus.enabled=false \
  istio-release/install/kubernetes/helm/istio > yaml/istio.yaml
```

- **部署 Istio 控制面**

```shell
# 安装
kubectl apply -f yaml/istio.yaml

# 验证
kubectl get svc -n istio-system -o wide
kubectl get pods -n istio-system -o wide

# 卸载
kubectl delete -f yaml/istio.yaml
```

## 安装附加服务

### prometheus

```shell
cp istio-release/install/kubernetes/helm/istio/templates/_affinity.tpl istio-release/install/kubernetes/helm/istio/charts/prometheus/templates/_affinity.tpl

helm template --name=istio --namespace istio-system \
  --values istio-release/install/kubernetes/helm/istio/values.yaml \
  --set enabled=true \
  --set hub=$LocalHub \
  istio-release/install/kubernetes/helm/istio/charts/prometheus > yaml/istio-prometheus.yaml

# 安装
kubectl apply -f yaml/istio-prometheus.yaml

# 卸载
kubectl delete -f yaml/istio-prometheus.yaml
```

```shell
cat <<EOF | kubectl -n istio-system apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prometheus
spec:
  rules:
  - host: prometheus.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: prometheus
          servicePort: http-prometheus
EOF
# 配置host： prometheus.sloth.com
```

访问：<http://prometheus.sloth.com>

### grafana

```shell
cp istio-release/install/kubernetes/helm/istio/templates/_affinity.tpl istio-release/install/kubernetes/helm/istio/charts/grafana/templates/_affinity.tpl
cp istio-release/install/kubernetes/helm/istio/templates/install-custom-resources.sh.tpl istio-release/install/kubernetes/helm/istio/charts/grafana/templates/install-custom-resources.sh.tpl

helm template --name=istio --namespace istio-system \
  --values istio-release/install/kubernetes/helm/istio/values.yaml \
  --set global.hub=$LocalHub \
  --set enabled=true \
  --set security.enabled=false \
  --set image.repository=$LocalHub/grafana \
  istio-release/install/kubernetes/helm/istio/charts/grafana > yaml/istio-grafana.yaml

# 安装
kubectl apply -f yaml/istio-grafana.yaml

# 卸载
kubectl delete -f yaml/istio-grafana.yaml
```

```shell
cat <<EOF | kubectl -n istio-system apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: grafana
spec:
  rules:
  - host: grafana.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: grafana
          servicePort: http
EOF
# 配置host： grafana.sloth.com
```

访问：<http://grafana.sloth.com>

### kiali

```shell
cp istio-release/install/kubernetes/helm/istio/templates/_affinity.tpl istio-release/install/kubernetes/helm/istio/charts/kiali/templates/_affinity.tpl

helm template --name=istio --namespace istio-system \
  --values istio-release/install/kubernetes/helm/istio/values.yaml \
  --set enabled=true \
  --set hub=$LocalHub \
  --set tag=v0.20 \
  --set createDemoSecret=true \
  --set dashboard.grafanaURL=http://grafana.sloth.com \
  istio-release/install/kubernetes/helm/istio/charts/kiali > yaml/istio-kiali.yaml

# 安装
 

# 卸载
kubectl delete -f yaml/istio-kiali.yaml
```

- 去除 kiali 登陆验证，**vi yaml/istio.yaml** || **ConfigMap:kiali**

```yaml
    auth:
      strategy: anonymous
```

- 配置 Ingress

```shell
cat <<EOF | kubectl -n istio-system apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kiali
spec:
  rules:
  - host: kiali.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kiali
          servicePort: http-kiali
EOF
# 配置host： kiali.sloth.com
```

访问：<http://kiali.sloth.com/kiali/> admin/admin

### tracing

```shell
cp istio-release/install/kubernetes/helm/istio/templates/_affinity.tpl istio-release/install/kubernetes/helm/istio/charts/tracing/templates/_affinity.tpl

# zipkin
helm template --name=istio --namespace istio-system \
  --values istio-release/install/kubernetes/helm/istio/values.yaml \
  --set enabled=true \
  --set provider=zipkin \
  --set zipkin.hub=$LocalHub \
  --set zipkin.resources.requests.cpu=100m \
  --set zipkin.resources.requests.memory=150Mi \
  istio-release/install/kubernetes/helm/istio/charts/tracing > yaml/istio-tracing.yaml

# jaeger
helm template --name=istio --namespace istio-system \
  --values istio-release/install/kubernetes/helm/istio/values.yaml \
  --set enabled=true \
  --set provider=jaeger \
  --set jaeger.hub=$LocalHub \
  istio-release/install/kubernetes/helm/istio/charts/tracing > yaml/istio-tracing.yaml

# 安装
kubectl apply -f yaml/istio-tracing.yaml

# 卸载
kubectl delete -f yaml/istio-tracing.yaml
```

- 配置 Ingress

```shell
cat <<EOF | kubectl -n istio-system apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: tracing
spec:
  rules:
  - host: tracing.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: tracing
          servicePort: http-query
EOF
# 配置host： tracing.sloth.com
```

访问：<http://tracing.sloth.com>

## istio 功能变更

- **调整采样率，默认采样率 1%**

```shell
# PILOT_TRACE_SAMPLING 100
kubectl -n istio-system edit deployment istio-pilot
```

- **开启双向TLS**

```shell
## 安装时开启双向TLS
  --set global.mtls.enabled=true \
  --set global.controlPlaneSecurityEnabled=true \
```

- **关闭访问日志**

- **变更调用链追踪地址**

- **kafka**
