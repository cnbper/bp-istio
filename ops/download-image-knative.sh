# gcr.io/knative-releases/knative.dev/serving/cmd/queue@sha256:5ff357b66622c98f24c56bba0a866be5e097306b83c5e6c41c28b6e87ec64c7c
# gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:0c52e0a85612bbedebf6d0de2b1951a4f762a05691f86e78079a5089d4848652
# gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler-hpa@sha256:f5514430997ed3799e0f708d657fef935e7eef2774f073a46ffb06311c8b5e76
# gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler@sha256:9b716bec384c166782f30756e0981ab11178e1a6b7a4fa6965cc6225abf8567c
# gcr.io/knative-releases/knative.dev/serving/cmd/controller@sha256:a168c9fa095c88b3e0bcbbaa6d4501a8a02ab740b360938879ae9df55964a758
# gcr.io/knative-releases/knative.dev/serving/cmd/webhook@sha256:f59e8d9782f17b1af3060152d99b70ae08f40aa69b799180d24964e527ebb818
# gcr.io/knative-releases/knative.dev/serving/cmd/networking/istio@sha256:4bc49ca99adf8e4f5c498bdd1287cdf643e4b721e69b2c4a022fe98db46486ff
# gcr.io/knative-releases/knative.dev/serving/cmd/networking/certmanager@sha256:1689ce4fa7f920859eca56ab891490be5ff4462b1e220c6fd7bf8405170d2979

# gcr.io/knative-releases/knative.dev/eventing/cmd/controller@sha256:82fdc37bd5fc99d756a7a5e21a14fcaff7ad0a1f09ef2c33197bca9af9b329ba
# gcr.io/knative-releases/knative.dev/eventing/cmd/sources_controller@sha256:27f0b025ea16907db2b52cb220894b91cac627c6fbff914fce90ae4d987f1b0b
# gcr.io/knative-releases/knative.dev/eventing/cmd/webhook@sha256:fb8c72dc3c2897193a04459e2e05fc56f47228fe37981d7b653e87f1725a54bb
# gcr.io/knative-releases/knative.dev/eventing/cmd/in_memory/channel_controller@sha256:b07cb2a452a348643a7e806965b90af05d2a89f99e98ae3285179dee3e7cf6cf
# gcr.io/knative-releases/knative.dev/eventing/cmd/in_memory/channel_dispatcher@sha256:7675ebbcb349a6362520d8210f25305d9863ff8a03668bb6b562322df9a47c18
# gcr.io/knative-releases/knative.dev/eventing/cmd/broker/ingress@sha256:09e0be131cf80431fb2fdaf06a865cc1f49d6aecf527878ced25af4c70cb4d3c
# gcr.io/knative-releases/knative.dev/eventing/cmd/broker/filter@sha256:94043bca23a08d26ffd6bdf7111464237d22413023c5ba4338b931a5eab242bd
# gcr.io/knative-releases/knative.dev/eventing/cmd/cronjob_receive_adapter@sha256:bdf30b32d57e1536fca5e436ce9c074827afd5f6f5eceed4cc0a8ca97096cefa
# gcr.io/knative-releases/knative.dev/eventing/cmd/apiserver_receive_adapter@sha256:67300996636df61f7271cfaed335b57daaea9496acebb6f8db68b9f81931b2db

# gcr.io/knative-releases/knative.dev/eventing-contrib/github/cmd/controller@sha256:b5a9f680818212112bcf30e4f7d34c373c8ff0867a7af8093f3b23be7aa694eb
# gcr.io/knative-releases/knative.dev/eventing-contrib/camel/source/cmd/controller@sha256:3ef02bae9153442485c0efffb7c9eb03431f54f1d571776891ec1731e27cd9ea
# gcr.io/knative-releases/knative.dev/eventing-contrib/kafka/source/cmd/controller@sha256:d42cbd1233f2cc6bd0e75c44679bd408423fe89056f4ce67e18ccbd41f5ce7e7
# gcr.io/knative-releases/knative.dev/eventing-contrib/kafka/channel/cmd/channel_controller@sha256:a4531579ca8854d6ca59071e4c1abbfa01fd472bd8ac98f69c2f6562fad38535
# gcr.io/knative-releases/knative.dev/eventing-contrib/kafka/channel/cmd/channel_dispatcher@sha256:f095d31a4685538e1abf777b9f3fc871aa1f38f431b65ff5948a6fa03785e3b2
# gcr.io/knative-releases/knative.dev/eventing-contrib/kafka/channel/cmd/webhook@sha256:467ad55b0ab9dd3317d263bb060fb9698a512cae9146ebecccce602239452142

RemoteRegistry=registry.sloth.com/ipaas

KnativeCurrentVersion=v0.10.0
KnativeOldVersion=v0.9.0
knative_modules=(
    "serving-queue" 
    "serving-activator" 
    "serving-autoscaler-hpa" 
    "serving-autoscaler" 
    "serving-controller" 
    "serving-webhook" 
    "serving-networking-istio" 
    "serving-networking-certmanager"
    "eventing-controller"
    "eventing-sources_controller"
    "eventing-webhook"
    "eventing-in_memory-channel_controller"
    "eventing-in_memory-channel_dispatcher"
    "eventing-broker-ingress"
    "eventing-broker-filter"
    "eventing-cronjob_receive_adapter"
    "eventing-apiserver_receive_adapter"
    "eventing-contrib-github-controller"
    "eventing-contrib-camel-source-controller"
    "eventing-contrib-kafka-source-controller"
    "eventing-contrib-kafka-channel-channel_controller"
    "eventing-contrib-kafka-channel-channel_dispatcher"
    "eventing-contrib-kafka-channel-webhook"
    )

for module in ${knative_modules[*]}
do
docker pull cknative/${module}:${KnativeCurrentVersion}
docker rmi cknative/${module}:${KnativeOldVersion}

docker tag cknative/${module}:$KnativeCurrentVersion ${RemoteRegistry}/${module}:${KnativeCurrentVersion}
docker push ${RemoteRegistry}/${module}:${KnativeCurrentVersion}
docker rmi ${RemoteRegistry}/${module}:${KnativeCurrentVersion}
done

# k8s.gcr.io/elasticsearch:v5.6.4
# alpine:3.6
# docker.elastic.co/kibana/kibana:5.6.4
# k8s.gcr.io/fluentd-elasticsearch:v2.0.4
# quay.io/coreos/kube-state-metrics:v1.7.2
# quay.io/prometheus/node-exporter:v0.15.2
# quay.io/coreos/kube-rbac-proxy:v0.3.0
# grafana/grafana:6.3.3
# prom/prometheus:v2.2.1
# docker.io/openzipkin/zipkin:2.13.0
