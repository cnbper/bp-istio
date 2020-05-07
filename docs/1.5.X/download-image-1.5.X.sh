RemoteRegistry=registry.sloth.com/ipaas

IstioCurrentVersion=1.5.2
IstioOldVersion=1.5.1
istio_modules=("kubectl" "galley" "mixer" "proxyv2" "pilot" "citadel" "sidecar_injector" "node-agent-k8s" "install-cni")

for module in ${istio_modules[*]}
do
docker pull istio/${module}:${IstioCurrentVersion}
docker rmi istio/${module}:${IstioOldVersion}

docker tag istio/${module}:$IstioCurrentVersion ${RemoteRegistry}/${module}:${IstioCurrentVersion}
docker push ${RemoteRegistry}/${module}:${IstioCurrentVersion}
docker rmi ${RemoteRegistry}/${module}:${IstioCurrentVersion}
done

docker pull grafana/grafana:6.4.3
docker tag grafana/grafana:6.4.3 ${RemoteRegistry}/grafana:6.4.3
docker push ${RemoteRegistry}/grafana:6.4.3
docker rmi ${RemoteRegistry}/grafana:6.4.3

docker pull quay.io/kiali/kiali:v1.9
docker tag quay.io/kiali/kiali:v1.9 ${RemoteRegistry}/kiali:v1.9
docker push ${RemoteRegistry}/kiali:v1.9
docker rmi ${RemoteRegistry}/kiali:v1.9

docker pull docker.io/prom/prometheus:v2.12.0
docker tag docker.io/prom/prometheus:v2.12.0 ${RemoteRegistry}/prometheus:v2.12.0
docker push ${RemoteRegistry}/prometheus:v2.12.0
docker rmi ${RemoteRegistry}/prometheus:v2.12.0

docker pull docker.io/jaegertracing/all-in-one:1.16
docker tag docker.io/jaegertracing/all-in-one:1.16 ${RemoteRegistry}/all-in-one:1.16
docker push ${RemoteRegistry}/all-in-one:1.16
docker rmi ${RemoteRegistry}/all-in-one:1.16