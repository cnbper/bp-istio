# Istio

<https://istio.io/docs/setup/kubernetes/install/helm/>
<https://istio.io/docs/reference/config/installation-options/>

## istio init

- **构建安装文件**

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
LocalHub=registry.sloth.com
## 默认开启双向TLS
helm template --name=istio --namespace istio-system \
  --set global.hub=$LocalHub/istio \
  --set global.tracer.zipkin.address="zipkin.zipkin-system:9411" \
  --set global.proxy.accessLogFile="/dev/stdout" \
  --set global.mtls.enabled=true \
  --set global.controlPlaneSecurityEnabled=true \
  --set global.proxy.resources.requests.cpu=100m \
  --set global.proxy.resources.requests.memory=128Mi \
  --set global.proxy.resources.limits.cpu=2000m \
  --set global.proxy.resources.limits.memory=1024Mi \
  --set pilot.resources.requests.cpu=100m \
  --set pilot.resources.requests.memory=512Mi \
  --set mixer.telemetry.resources.requests.cpu=250m \
  --set mixer.telemetry.resources.requests.memory=256Mi \
  --set mixer.telemetry.resources.limits.cpu=4800m \
  --set mixer.telemetry.resources.limits.memory=4G \
  --set gateways.enabled=false \
  --set gateways.istio-ingressgateway.type=NodePort \
  --set prometheus.enabled=true \
  --set prometheus.hub=$LocalHub/prom \
  --set grafana.enabled=true \
  --set grafana.image.repository=$LocalHub/grafana/grafana \
  --set kiali.enabled=true \
  --set kiali.hub=$LocalHub/kiali \
  --set kiali.tag=v0.20 \
  --set kiali.createDemoSecret=true \
  --set kiali.dashboard.grafanaURL=http://grafana.sloth.com \
  --set servicegraph.enabled=false \
  istio-release/install/kubernetes/helm/istio > yaml/istio.yaml
```

- 去除 kiali 登陆验证，**vi yaml/istio.yaml** || **ConfigMap:kiali**

```yaml
    auth:
      strategy: anonymous
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

## 暴露控制面服务

- prometheus

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

- grafana

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

- kiali

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
