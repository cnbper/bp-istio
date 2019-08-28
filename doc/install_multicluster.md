# 集群感知的服务路由

<https://istio.io/docs/examples/multicluster/split-horizon-eds/>

```shell
# 使用 Helm 创建 Istio cluster1 的部署 YAML
helm template --name=istio --namespace=istio-system \
  --set global.mtls.enabled=true \
  --set security.selfSigned=false \
  --set global.controlPlaneSecurityEnabled=true \
  --set global.proxy.accessLogFile="/dev/stdout" \
  --set global.meshExpansion.enabled=true \
  --set 'global.meshNetworks.network1.endpoints[0].fromRegistry'=Kubernetes \
  --set 'global.meshNetworks.network1.gateways[0].address'=0.0.0.0 \
  --set 'global.meshNetworks.network1.gateways[0].port'=443 \
  --set gateways.istio-ingressgateway.env.ISTIO_META_NETWORK="network1" \
  --set global.network="network1" \
  --set 'global.meshNetworks.network2.endpoints[0].fromRegistry'=n2-k8s-config \
  --set 'global.meshNetworks.network2.gateways[0].address'=0.0.0.0 \
  --set 'global.meshNetworks.network2.gateways[0].port'=443 \
  install/kubernetes/helm/istio > istio-auth.yaml

kubectl create --context=$CTX_CLUSTER1 ns istio-system
kubectl create --context=$CTX_CLUSTER1 secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply --context=$CTX_CLUSTER1 -f $i; done
kubectl apply --context=$CTX_CLUSTER1 -f istio-auth.yaml

```