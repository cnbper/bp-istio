IstioCurrentVersion=1.1.7
IstioOldVersion=1.1.6
RemoteRegistry=registry.sloth.com

istio_modules=("istio/proxy_init" "istio/proxyv2" "istio/kubectl" "istio/galley" "istio/mixer" "istio/pilot" "istio/citadel" "istio/sidecar_injector" "istio/node-agent-k8s" "istio/servicegraph")

for module in ${istio_modules[*]}
do
docker pull ${module}:$IstioCurrentVersion
docker rmi ${module}:$IstioOldVersion

docker tag ${module}:$IstioCurrentVersion ${RemoteRegistry}/${module}:$IstioCurrentVersion
docker push ${RemoteRegistry}/${module}:$IstioCurrentVersion
docker rmi ${RemoteRegistry}/${module}:$IstioCurrentVersion
done

PrometheusCurrentVersion=v2.3.1
docker pull prom/prometheus:${PrometheusCurrentVersion}
docker tag prom/prometheus:${PrometheusCurrentVersion} ${RemoteRegistry}/prom/prometheus:${PrometheusCurrentVersion}
docker push ${RemoteRegistry}/prom/prometheus:${PrometheusCurrentVersion}
docker rmi ${RemoteRegistry}/prom/prometheus:${PrometheusCurrentVersion}

GrafanaCurrentVersion=6.0.2
docker pull grafana/grafana:${GrafanaCurrentVersion}
docker tag grafana/grafana:${GrafanaCurrentVersion} ${RemoteRegistry}/grafana/grafana:${GrafanaCurrentVersion}
docker push ${RemoteRegistry}/grafana/grafana:${GrafanaCurrentVersion}
docker rmi ${RemoteRegistry}/grafana/grafana:${GrafanaCurrentVersion}

KialiCurrentVersion=v0.16
docker pull docker.io/kiali/kiali:${KialiCurrentVersion}
docker tag docker.io/kiali/kiali:${KialiCurrentVersion} ${RemoteRegistry}/kiali/kiali:${KialiCurrentVersion}
docker push ${RemoteRegistry}/kiali/kiali:${KialiCurrentVersion}
docker rmi ${RemoteRegistry}/kiali/kiali:${KialiCurrentVersion}

docker pull docker.io/kennethreitz/httpbin
docker tag docker.io/kennethreitz/httpbin ${RemoteRegistry}/kennethreitz/httpbin
docker push ${RemoteRegistry}/kennethreitz/httpbin
docker rmi ${RemoteRegistry}/kennethreitz/httpbin

docker pull pstauffer/curl
docker tag pstauffer/curl ${RemoteRegistry}/pstauffer/curl
docker push ${RemoteRegistry}/pstauffer/curl
docker rmi ${RemoteRegistry}/pstauffer/curl

BookinfoOldVersion=1.12.0
BookinfoCurrentVersion=1.13.0
bookinfo_modules=("istio/examples-bookinfo-productpage-v1" "istio/examples-bookinfo-details-v1" "istio/examples-bookinfo-details-v2" "istio/examples-bookinfo-reviews-v1" "istio/examples-bookinfo-reviews-v2" "istio/examples-bookinfo-reviews-v3" "istio/examples-bookinfo-ratings-v1" "istio/examples-bookinfo-ratings-v2" "istio/examples-bookinfo-mysqldb" "istio/examples-bookinfo-mongodb")
for module in ${bookinfo_modules[*]}
do
docker pull ${module}:$BookinfoCurrentVersion
docker rmi ${module}:$BookinfoOldVersion

docker tag ${module}:$BookinfoCurrentVersion ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
docker push ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
docker rmi ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
done

