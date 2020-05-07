IstioCurrentVersion=1.3.8
istio_modules=("kubectl" "galley" "mixer" "proxyv2" "pilot" "citadel" "sidecar_injector" "node-agent-k8s" "proxy_init" "install-cni")

for module in ${istio_modules[*]}
do
docker image save -o $IstioCurrentVersion/image/${module}.tar istio/${module}:$IstioCurrentVersion
done
