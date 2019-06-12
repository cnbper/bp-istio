RemoteRegistry=registry.sloth.com

IstioCurrentVersion=1.2.0-rc.0
IstioOldVersion=1.1.7
istio_modules=("proxy_init" "proxyv2" "kubectl" "galley" "mixer" "pilot" "citadel" "sidecar_injector" "node-agent-k8s")

for module in ${istio_modules[*]}
do
docker pull istio/${module}:${IstioCurrentVersion}
docker rmi istio/${module}:${IstioOldVersion}

docker tag istio/${module}:$IstioCurrentVersion ${RemoteRegistry}/istio/${module}:${IstioCurrentVersion}
docker push ${RemoteRegistry}/istio/${module}:${IstioCurrentVersion}
docker rmi ${RemoteRegistry}/istio/${module}:${IstioCurrentVersion}
done

PrometheusCurrentVersion=v2.8.0

docker pull prom/prometheus:${PrometheusCurrentVersion}
docker tag prom/prometheus:${PrometheusCurrentVersion} ${RemoteRegistry}/prom/prometheus:${PrometheusCurrentVersion}
docker push ${RemoteRegistry}/prom/prometheus:${PrometheusCurrentVersion}
docker rmi ${RemoteRegistry}/prom/prometheus:${PrometheusCurrentVersion}

GrafanaCurrentVersion=6.1.6

docker pull grafana/grafana:${GrafanaCurrentVersion}
docker tag grafana/grafana:${GrafanaCurrentVersion} ${RemoteRegistry}/grafana/grafana:${GrafanaCurrentVersion}
docker push ${RemoteRegistry}/grafana/grafana:${GrafanaCurrentVersion}
docker rmi ${RemoteRegistry}/grafana/grafana:${GrafanaCurrentVersion}

KialiCurrentVersion=v0.20
KialiOldVersion=v0.16

docker pull docker.io/kiali/kiali:${KialiCurrentVersion}
docker tag docker.io/kiali/kiali:${KialiCurrentVersion} ${RemoteRegistry}/kiali/kiali:${KialiCurrentVersion}
docker push ${RemoteRegistry}/kiali/kiali:${KialiCurrentVersion}
docker rmi ${RemoteRegistry}/kiali/kiali:${KialiCurrentVersion}
docker rmi docker.io/kiali/kiali:${KialiOldVersion}

JaegertracingCurrentVersion=1.9

docker pull docker.io/jaegertracing/all-in-one:${JaegertracingCurrentVersion}
docker tag docker.io/jaegertracing/all-in-one:${JaegertracingCurrentVersion} ${RemoteRegistry}/jaegertracing/all-in-one:${JaegertracingCurrentVersion}
docker push ${RemoteRegistry}/jaegertracing/all-in-one:${JaegertracingCurrentVersion}
docker rmi ${RemoteRegistry}/jaegertracing/all-in-one:${JaegertracingCurrentVersion}

BookinfoCurrentVersion=1.12.0
BookinfoOldVersion=1.11.0

bookinfo_modules=("istio/examples-bookinfo-productpage-v1" "istio/examples-bookinfo-details-v1" "istio/examples-bookinfo-details-v2" "istio/examples-bookinfo-reviews-v1" "istio/examples-bookinfo-reviews-v2" "istio/examples-bookinfo-reviews-v3" "istio/examples-bookinfo-ratings-v1" "istio/examples-bookinfo-ratings-v2" "istio/examples-bookinfo-mysqldb" "istio/examples-bookinfo-mongodb")
for module in ${bookinfo_modules[*]}
do
docker pull ${module}:$BookinfoCurrentVersion
docker rmi ${module}:$BookinfoOldVersion

docker tag ${module}:$BookinfoCurrentVersion ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
docker push ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
docker rmi ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
done

docker pull docker.io/kennethreitz/httpbin
docker tag docker.io/kennethreitz/httpbin ${RemoteRegistry}/kennethreitz/httpbin
docker push ${RemoteRegistry}/kennethreitz/httpbin
docker rmi ${RemoteRegistry}/kennethreitz/httpbin

docker pull pstauffer/curl
docker tag pstauffer/curl ${RemoteRegistry}/pstauffer/curl
docker push ${RemoteRegistry}/pstauffer/curl
docker rmi ${RemoteRegistry}/pstauffer/curl
