# Customizable Install with Istioctl

<https://istio.io/docs/setup/install/istioctl/>

```shell
LocalHub=registry.sloth.com/ipaas
IstioTag=1.4.0-dev

istioctl manifest \
    --set hub=$LocalHub \
    --set tag=$IstioTag \
    --set security.components.certManager.enabled=true \
    --set values.global.enableTracing=false \
    --set values.global.proxy.accessLogFile="/dev/stdout" \
    --set values.global.proxy.accessLogFormat="" \
    --set values.global.proxy.resources.requests.cpu=50m \
    --set values.global.proxy.resources.requests.memory=64Mi \
    --set values.global.policyCheckFailOpen=true \
    --set values.global.imagePullPolicy=Always \
    --set values.global.outboundTrafficPolicy.mode=ALLOW_ANY \
    --set values.pilot.autoscaleMin=1 \
    --set values.pilot.resources.requests.cpu=62m \
    --set values.pilot.resources.requests.memory=256Mi \
    --set values.pilot.traceSampling=100.0 \
    --set values.mixer.policy.autoscaleMin=1 \
    --set values.mixer.telemetry.autoscaleMin=1 \
    --set values.mixer.telemetry.resources.requests.cpu=125m \
    --set values.mixer.telemetry.resources.requests.memory=128Mi \
    --set values.galley.replicaCount=1 \
    --set values.security.replicaCount=1 \
    --set gateways.enabled=false \
    --set values.prometheus.enabled=false \
    --set values.sidecarInjectorWebhook.replicaCount=1 \
    generate > istio.yaml

kubectl apply -f istio.yaml
```
