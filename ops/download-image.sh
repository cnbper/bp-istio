IstioCurrentVersion=1.1.5
IstioOldVersion=1.1.3

istio_modules=("istio/proxy_init" "istio/proxyv2" "istio/kubectl" "istio/galley" "istio/mixer" "istio/pilot" "istio/citadel" "istio/sidecar_injector")

for module in ${istio_modules[*]}
do
docker pull ${module}:$IstioCurrentVersion
docker rmi ${module}:$IstioOldVersion

docker tag ${module}:$IstioCurrentVersion registry.sloth.com/${module}:$IstioCurrentVersion
docker push registry.sloth.com/${module}:$IstioCurrentVersion
docker rmi registry.sloth.com/${module}:$IstioCurrentVersion
done


docker pull busybox:1.30.1
docker pull prom/prometheus:v2.3.1

docker pull istio/examples-bookinfo-details-v1:1.10.1
docker pull istio/examples-bookinfo-ratings-v1:1.10.1
docker pull istio/examples-bookinfo-reviews-v1:1.10.1
docker pull istio/examples-bookinfo-reviews-v2:1.10.1
docker pull istio/examples-bookinfo-reviews-v3:1.10.1
docker pull istio/examples-bookinfo-productpage-v1:1.10.1



