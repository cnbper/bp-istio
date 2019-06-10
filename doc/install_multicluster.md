# 集群感知的服务路由

<https://istio.io/docs/examples/multicluster/split-horizon-eds/>

```shell
# 使用 Helm 创建 Istio cluster1 的部署 YAML
helm template --name=istio --namespace=istio-system \
  --set global.hub=$LocalHub/istio \
  --set prometheus.enabled=false \
  --set gateways.istio-ingressgateway.type=NodePort \
  --set global.mtls.enabled=true \
  --set security.selfSigned=false \
  --set global.controlPlaneSecurityEnabled=true \
  --set global.proxy.accessLogFile="/dev/stdout" \
  # --set global.meshExpansion.enabled=true \
  --set 'global.meshNetworks.network2.endpoints[0].fromRegistry'=n2-k8s-config \
  --set 'global.meshNetworks.network2.gateways[0].address'=0.0.0.0 \
  --set 'global.meshNetworks.network2.gateways[0].port'=443 \
  istio-release/install/kubernetes/helm/istio > yaml/istio-auth2.yaml

kubectl -n istio-system create secret generic cacerts \
  --from-file=istio-release/samples/certs/ca-cert.pem \
  --from-file=istio-release/samples/certs/ca-key.pem \
  --from-file=istio-release/samples/certs/root-cert.pem \
  --from-file=istio-release/samples/certs/cert-chain.pem

```