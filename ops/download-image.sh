RemoteRegistry=registry.sloth.com/ipaas

IstioCurrentVersion=1.4.3
IstioOldVersion=1.4.2
istio_modules=("kubectl" "galley" "mixer" "proxyv2" "pilot" "citadel" "sidecar_injector" "node-agent-k8s" "proxy_init")

for module in ${istio_modules[*]}
do
docker pull istio/${module}:${IstioCurrentVersion}
docker rmi istio/${module}:${IstioOldVersion}

docker tag istio/${module}:$IstioCurrentVersion ${RemoteRegistry}/${module}:${IstioCurrentVersion}
docker push ${RemoteRegistry}/${module}:${IstioCurrentVersion}
docker rmi ${RemoteRegistry}/${module}:${IstioCurrentVersion}
done

# docker pull istio/coredns-plugin:0.2-istio-1.1
# docker pull coredns/coredns:1.6.2

# PrometheusCurrentVersion=v2.12.0
# docker pull prom/prometheus:${PrometheusCurrentVersion}
# docker tag prom/prometheus:${PrometheusCurrentVersion} ${RemoteRegistry}/prometheus:${PrometheusCurrentVersion}
# docker push ${RemoteRegistry}/prometheus:${PrometheusCurrentVersion}
# docker rmi ${RemoteRegistry}/prometheus:${PrometheusCurrentVersion}

# GrafanaCurrentVersion=6.4.3
# docker pull grafana/grafana:${GrafanaCurrentVersion}
# docker tag grafana/grafana:${GrafanaCurrentVersion} ${RemoteRegistry}/grafana:${GrafanaCurrentVersion}
# docker push ${RemoteRegistry}/grafana:${GrafanaCurrentVersion}
# docker rmi ${RemoteRegistry}/grafana:${GrafanaCurrentVersion}

# KialiCurrentVersion=v1.9
# docker pull docker.io/kiali/kiali:${KialiCurrentVersion}
# docker tag docker.io/kiali/kiali:${KialiCurrentVersion} ${RemoteRegistry}/kiali:${KialiCurrentVersion}
# docker push ${RemoteRegistry}/kiali:${KialiCurrentVersion}
# docker rmi ${RemoteRegistry}/kiali:${KialiCurrentVersion}

# OpenzipkinVersion=2.14.2
# docker pull docker.io/openzipkin/zipkin:${OpenzipkinVersion}
# docker tag docker.io/openzipkin/zipkin:${OpenzipkinVersion} ${RemoteRegistry}/zipkin:${OpenzipkinVersion}
# docker push ${RemoteRegistry}/zipkin:${OpenzipkinVersion}
# docker rmi ${RemoteRegistry}/zipkin:${OpenzipkinVersion}

# JaegertracingCurrentVersion=1.14
# docker pull docker.io/jaegertracing/all-in-one:${JaegertracingCurrentVersion}
# docker tag docker.io/jaegertracing/all-in-one:${JaegertracingCurrentVersion} ${RemoteRegistry}/all-in-one:${JaegertracingCurrentVersion}
# docker push ${RemoteRegistry}/all-in-one:${JaegertracingCurrentVersion}
# docker rmi ${RemoteRegistry}/all-in-one:${JaegertracingCurrentVersion}


# BookinfoCurrentVersion=1.15.0
# BookinfoOldVersion=1.12.0

# bookinfo_modules=("examples-bookinfo-productpage-v1" "examples-bookinfo-details-v1" "examples-bookinfo-details-v2" "examples-bookinfo-reviews-v1" "examples-bookinfo-reviews-v2" "examples-bookinfo-reviews-v3" "examples-bookinfo-ratings-v1" "examples-bookinfo-ratings-v2" "examples-bookinfo-mysqldb" "examples-bookinfo-mongodb")
# for module in ${bookinfo_modules[*]}
# do
# docker pull istio/${module}:$BookinfoCurrentVersion
# docker rmi istio/${module}:$BookinfoOldVersion

# docker tag istio/${module}:$BookinfoCurrentVersion ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
# docker push ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
# docker rmi ${RemoteRegistry}/${module}:$BookinfoCurrentVersion
# done

# docker pull docker.io/kennethreitz/httpbin
# docker tag docker.io/kennethreitz/httpbin ${RemoteRegistry}/httpbin
# docker push ${RemoteRegistry}/httpbin
# docker rmi ${RemoteRegistry}/httpbin

# docker pull pstauffer/curl
# docker tag pstauffer/curl ${RemoteRegistry}/curl
# docker push ${RemoteRegistry}/curl
# docker rmi ${RemoteRegistry}/curl

# docker pull governmentpaas/curl-ssl
# docker tag governmentpaas/curl-ssl ${RemoteRegistry}/curl-ssl
# docker push ${RemoteRegistry}/curl-ssl
# docker rmi ${RemoteRegistry}/curl-ssl
