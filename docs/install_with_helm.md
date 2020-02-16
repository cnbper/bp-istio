# Istio

<https://istio.io/docs/setup/kubernetes/install/helm/>
<https://istio.io/docs/reference/config/installation-options/>

```shell
# kubectl label nodes kube-node1 istio.control.plane=yes
# kubectl label nodes kube-node2 istio.control.plane=yes
# kubectl label nodes kube-node1 istio.data.plane=yes
# kubectl label nodes kube-node2 istio.data.plane=yes
#  annotations:
#    scheduler.alpha.kubernetes.io/node-selector: istio.control.plane=yes

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: istio-system
EOF
```

## istio init

### kubernetes 1.13+

- **构建安装文件**

```shell
# 构建yaml文件
LocalHub=registry.sloth.com/ipaas
IstioTag=1.4.4

# yaml/istio-init.yaml
helm template --name=istio-init --namespace istio-system \
  --set global.hub=$LocalHub \
  --set global.tag=$IstioTag \
  --set global.imagePullPolicy=Always \
  --set certmanager.enabled=true \
  istio-release/install/kubernetes/helm/istio-init > yaml/istio-init.yaml
```

- **安装crd**

```shell
# 安装
kubectl apply -f yaml/istio-init.yaml

# 验证 28
kubectl wait --for=condition=complete job --all
kubectl -n istio-system get pod
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

### kubernetes 1.11

```shell
# 构建yaml文件
cat istio-release/install/kubernetes/helm/istio-init/files/crd-10.yaml | sed -e 's/preserveUnknownFields: false/preserveUnknownFields: true/g' | sed -e 's/type: object//g' >> yaml/istio-crd.yaml
cat istio-release/install/kubernetes/helm/istio-init/files/crd-11.yaml | sed -e 's/preserveUnknownFields: false/preserveUnknownFields: true/g' | sed -e 's/type: object//g' >> yaml/istio-crd.yaml
cat istio-release/install/kubernetes/helm/istio-init/files/crd-14.yaml | sed -e 's/preserveUnknownFields: false/preserveUnknownFields: true/g' | sed -e 's/type: object//g' >> yaml/istio-crd.yaml
cat istio-release/install/kubernetes/helm/istio-init/files/crd-certmanager-10.yaml | sed -e 's/preserveUnknownFields: false/preserveUnknownFields: true/g' | sed -e 's/type: object//g' >> yaml/istio-crd.yaml
cat istio-release/install/kubernetes/helm/istio-init/files/crd-certmanager-11.yaml | sed -e 's/preserveUnknownFields: false/preserveUnknownFields: true/g' | sed -e 's/type: object//g' >> yaml/istio-crd.yaml

# 安装
kubectl apply -f yaml/istio-crd.yaml

# 验证 28
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

# 卸载
# kubectl delete -f yaml/istio-crd.yaml
```

## istio控制面

- **构建istio控制面安装文件**

```shell
# 构建yaml文件
LocalHub=registry.sloth.com/ipaas
IstioTag=1.4.4

# 最小安装
# --set global.proxy.accessLogFile="/dev/stdout" \
# --set global.tracer.zipkin.address="zipkin.istio-system:9411" \
# --set pilot.traceSampling=100.0 \
# --set global.outboundTrafficPolicy.mode=REGISTRY_ONLY \

# https://istio.io/docs/tasks/security/citadel-config/health-check/
# Since Citadel health checking currently only monitors the health status of CSR service API, this feature is not needed if the production setup is not using SDS or adding virtual machines.
# --set security.citadelHealthCheck=true \

helm template --name=istio --namespace istio-system \
  --set global.hub=$LocalHub \
  --set global.tag=$IstioTag \
  --set global.enableTracing=false \
  --set global.proxy.accessLogFile="/dev/stdout" \
  --set global.proxy.accessLogFormat="" \
  --set global.proxy.resources.requests.cpu=50m \
  --set global.proxy.resources.requests.memory=64Mi \
  --set global.policyCheckFailOpen=true \
  --set global.imagePullPolicy=Always \
  --set global.outboundTrafficPolicy.mode=ALLOW_ANY \
  --set global.proxy.dnsRefreshRate=300s \
  --set pilot.autoscaleMin=1 \
  --set pilot.resources.requests.cpu=60m \
  --set pilot.resources.requests.memory=256Mi \
  --set pilot.env.PILOT_HTTP10=1 \
  --set pilot.env.PILOT_BLOCK_HTTP_ON_443=false \
  --set mixer.policy.autoscaleMin=1 \
  --set mixer.telemetry.autoscaleMin=1 \
  --set mixer.telemetry.resources.requests.cpu=125m \
  --set mixer.telemetry.resources.requests.memory=128Mi \
  --set mixer.adapters.prometheus.metricsExpiryDuration=10m \
  --set galley.replicaCount=1 \
  --set security.replicaCount=1 \
  --set gateways.enabled=false \
  --set prometheus.enabled=false \
  --set sidecarInjectorWebhook.replicaCount=1 \
  istio-release/install/kubernetes/helm/istio > yaml/istio.yaml

# 调整访问日志格式
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

### 监控面板

```shell
IstioCurVersion=istio-1.4.3

mkdir -p yaml/monitor/$IstioCurVersion
cp -r istio-release/install/kubernetes/helm/istio/charts/grafana yaml/monitor/$IstioCurVersion
cp -r istio-release/install/kubernetes/helm/istio/charts/prometheus yaml/monitor/$IstioCurVersion
```

- 通过 Beyond Compare 对比监控配置变化

1.3.2 升级到 1.4.2 ：galley-dashboard.json
1.4.2 升级到 1.4.3 ：无变化

### prometheus

```shell
cp istio-release/install/kubernetes/helm/istio/templates/_affinity.tpl istio-release/install/kubernetes/helm/istio/charts/prometheus/templates/_affinity.tpl

helm template --name=istio --namespace istio-system \
  --values istio-release/install/kubernetes/helm/istio/values.yaml \
  --set enabled=true \
  --set hub=$LocalHub \
  --set replicaCount=1 \
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
# rm -rf istio-release/install/kubernetes/helm/istio/charts/kiali
# cp -r /Users/zhangbaohao/software/golang/workspace/src/istio.io/istio/install/kubernetes/helm/istio/charts/kiali istio-release/install/kubernetes/helm/istio/charts/kiali

cp istio-release/install/kubernetes/helm/istio/templates/_affinity.tpl istio-release/install/kubernetes/helm/istio/charts/kiali/templates/_affinity.tpl

helm template --name=istio --namespace istio-system \
  --values istio-release/install/kubernetes/helm/istio/values.yaml \
  --set enabled=true \
  --set hub=$LocalHub \
  --set createDemoSecret=true \
  --set dashboard.grafanaURL=http://grafana.sloth.com \
  --set prometheusAddr=http://prometheus:9090 \
  --set replicaCount=1 \
  --set security.enabled=false \
  istio-release/install/kubernetes/helm/istio/charts/kiali > yaml/istio-kiali.yaml

# 安装
kubectl apply -f yaml/istio-kiali.yaml

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
