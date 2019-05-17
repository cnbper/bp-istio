# kong



kubectl -n istio-samples get pod
kubectl -n istio-samples exec -it productpage-v1-76786b6bd7-8zw75  /bin/bash
kubectl -n istio-samples exec -t productpage-v1-76786b6bd7-8zw75 -c istio-proxy -- netstat -ln
kubectl -n istio-samples exec -it details-v1-57fd679d85-vznmt  /bin/bash
kubectl -n istio-samples exec -it reviews-v1-6c89fccdf6-vx9w8  /bin/bash

kubectl get pod -n kong
kubectl -n kong exec -it kong-6d9cb5c75c-slr7w -c kong-proxy sh

wget http://details:9080/details/0
wget http://details-app.istio-app:9080/details/0

kubectl -n kong logs -f kong-6d9cb5c75c-slr7w istio-proxy

kubectl exec -it httpbin-6cc88595bf-bqj6j /bin/bash

istioctl -n istio-samples proxy-config listeners productpage-v1-76786b6bd7-8zw75 --address 0.0.0.0 --port 9080 -o json
istioctl -n istio-samples proxy-config routes productpage-v1-76786b6bd7-8zw75 --name 9080 -o json
istioctl -n istio-samples proxy-config clusters productpage-v1-76786b6bd7-8zw75 --fqdn reviews.istio-samples.svc.cluster.local -o json