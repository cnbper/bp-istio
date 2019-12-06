# Install Knative with Istio

<https://knative.dev/docs/install/knative-custom-install/>

## Serving Component

```shell
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/serving.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/serving-cert-manager.yaml

sed -i '' "s/gcr.io\/knative-releases\/knative.dev/registry.sloth.com\/ipaas/g" yaml/knative/v0.10.0/serving.yaml
sed -i '' "s/gcr.io\/knative-releases\/knative.dev/registry.sloth.com\/ipaas/g" yaml/knative/v0.10.0/serving-cert-manager.yaml

# 安装CRD
kubectl apply --selector knative.dev/crd-install=true -f yaml/knative/v0.10.0/serving.yaml
# 安装
kubectl apply -f yaml/knative/v0.10.0/serving.yaml

kubectl get pods --namespace knative-serving
```

## Observability Plugins

```shell
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/monitoring.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/monitoring-logs-elasticsearch.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/monitoring-metrics-prometheus.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/monitoring-tracing-jaeger.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/monitoring-tracing-jaeger-in-mem.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/monitoring-tracing-zipkin.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/serving/releases/download/v0.10.0/monitoring-tracing-zipkin-in-mem.yaml

kubectl get pods --namespace knative-monitoring
```

## Eventing Component

```shell
wget -P yaml/knative/v0.10.0 https://github.com/knative/eventing/releases/download/v0.10.0/release.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/eventing/releases/download/v0.10.0/eventing.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/eventing/releases/download/v0.10.0/in-memory-channel.yaml

sed -i '' "s/gcr.io\/knative-releases\/knative.dev/registry.sloth.com\/ipaas/g" yaml/knative/v0.10.0/release.yaml
sed -i '' "s/gcr.io\/knative-releases\/knative.dev/registry.sloth.com\/ipaas/g" yaml/knative/v0.10.0/eventing.yaml
sed -i '' "s/gcr.io\/knative-releases\/knative.dev/registry.sloth.com\/ipaas/g" yaml/knative/v0.10.0/in-memory-channel.yaml

# 安装CRD
kubectl apply --selector knative.dev/crd-install=true -f yaml/knative/v0.10.0/release.yaml
# 安装
kubectl apply -f yaml/knative/v0.10.0/release.yaml

kubectl get pods --namespace knative-eventing
```

## Eventing Resources

```shell
wget -P yaml/knative/v0.10.0 https://github.com/knative/eventing-contrib/releases/download/v0.10.0/github.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/eventing-contrib/releases/download/v0.10.0/camel.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/eventing-contrib/releases/download/v0.10.0/kafka-source.yaml
wget -P yaml/knative/v0.10.0 https://github.com/knative/eventing-contrib/releases/download/v0.10.0/kafka-channel.yaml
```

## 
