IstioCurrentVersion=1.1.7
IstioOldVersion=1.1.6

istio_modules=("istio/proxy_init" "istio/proxyv2" "istio/kubectl" "istio/galley" "istio/mixer" "istio/pilot" "istio/citadel" "istio/sidecar_injector" "istio/node-agent-k8s" "istio/servicegraph")

for module in ${istio_modules[*]}
do
docker pull ${module}:$IstioCurrentVersion
docker rmi ${module}:$IstioOldVersion

docker tag ${module}:$IstioCurrentVersion registry.sloth.com/${module}:$IstioCurrentVersion
docker push registry.sloth.com/${module}:$IstioCurrentVersion
docker rmi registry.sloth.com/${module}:$IstioCurrentVersion
done


docker pull prom/prometheus:v2.3.1
docker pull grafana/grafana:6.0.2
docker pull docker.io/kiali/kiali:v0.16

docker pull istio/examples-bookinfo-details-v1:1.13.0
docker pull istio/examples-bookinfo-ratings-v1:1.13.0
docker pull istio/examples-bookinfo-ratings-v2:1.13.0
docker pull istio/examples-bookinfo-reviews-v1:1.13.0
docker pull istio/examples-bookinfo-reviews-v2:1.13.0
docker pull istio/examples-bookinfo-reviews-v3:1.13.0
docker pull istio/examples-bookinfo-productpage-v1:1.13.0

docker pull docker.io/kennethreitz/httpbin
docker pull pstauffer/curl
