# istio metrics

<https://istio.io/docs/tasks/observability/metrics/>
<https://istio.io/docs/reference/config/policy-and-telemetry/adapters/prometheus/>

## prometheus

<https://prometheus.io/docs/querying/basics/>

- scrape_interval 数据采集时间间隔 15s

## metrics

- istio_requests_total | telemetry

```json
kubectl -n istio-system get instance requestcount
kubectl -n istio-system get handler prometheus
kubectl -n istio-system get rule promhttp

reporter=source      来自于源 Envoy
reporter=destination 来自于目标 Envoy
```

- istio_tcp_sent_bytes_total

- istio_request_duration_seconds_sum

- istio_request_bytes_sum

- istio_response_bytes_sum

- istio_tcp_received_bytes_total

- istio_response_bytes_bucket

- istio_request_bytes_bucket

## Collecting Metrics

```shell
kubectl -n istio-system get instance
kubectl -n istio-system get rule
kubectl -n istio-system get handler
```

```shell
http://prometheus.sloth.com/api/v1/query_range?query=istio_requests_total&start=1575531600&end=1575535200&step=14&_=1575534808414

2019-12-05 15:40:00

{"status":"success","data":{"resultType":"matrix","result":[{"metric":{"__name__":"istio_requests_total","connection_security_policy":"none","destination_app":"httpbin","destination_principal":"unknown","destination_service":"httpbin.samples.svc.cluster.local","destination_service_name":"httpbin","destination_service_namespace":"samples","destination_version":"v1","destination_workload":"httpbin","destination_workload_namespace":"samples","instance":"10.244.1.6:42422","job":"istio-mesh","permissive_response_code":"none","permissive_response_policyid":"none","reporter":"destination","request_protocol":"http","response_code":"200","response_flags":"-","source_app":"sleep","source_principal":"unknown","source_version":"unknown","source_workload":"sleep","source_workload_namespace":"samples"},"values":[[1575534806,"3"],[1575534820,"3"],[1575534834,"3"],[1575534848,"3"],[1575534862,"3"],[1575534876,"3"],[1575534890,"3"],[1575534904,"3"],[1575534918,"3"],[1575534932,"3"],[1575534946,"3"],[1575534960,"3"],[1575534974,"3"],[1575534988,"3"],[1575535002,"3"],[1575535016,"3"],[1575535030,"3"],[1575535044,"3"],[1575535058,"3"],[1575535072,"3"],[1575535086,"3"],[1575535100,"3"],[1575535114,"3"],[1575535128,"3"],[1575535142,"3"],[1575535156,"3"],[1575535170,"3"]]},{"metric":{"__name__":"istio_requests_total","connection_security_policy":"none","destination_app":"telemetry","destination_principal":"unknown","destination_service":"istio-telemetry.istio-system.svc.cluster.local","destination_service_name":"istio-telemetry","destination_service_namespace":"istio-system","destination_version":"unknown","destination_workload":"istio-telemetry","destination_workload_namespace":"istio-system","instance":"10.244.1.6:42422","job":"istio-mesh","permissive_response_code":"none","permissive_response_policyid":"none","reporter":"destination","request_protocol":"grpc","response_code":"200","response_flags":"-","source_app":"httpbin","source_principal":"unknown","source_version":"v1","source_workload":"httpbin","source_workload_namespace":"samples"},"values":[[1575534806,"3"],[1575534820,"3"],[1575534834,"3"],[1575534848,"3"],[1575534862,"3"],[1575534876,"3"],[1575534890,"3"],[1575534904,"3"],[1575534918,"3"],[1575534932,"3"],[1575534946,"3"],[1575534960,"3"],[1575534974,"3"],[1575534988,"3"],[1575535002,"3"],[1575535016,"3"],[1575535030,"3"],[1575535044,"3"],[1575535058,"3"],[1575535072,"3"],[1575535086,"3"],[1575535100,"3"],[1575535114,"3"],[1575535128,"3"],[1575535142,"3"],[1575535156,"3"],[1575535170,"3"]]},{"metric":{"__name__":"istio_requests_total","connection_security_policy":"none","destination_app":"telemetry","destination_principal":"unknown","destination_service":"istio-telemetry.istio-system.svc.cluster.local","destination_service_name":"istio-telemetry","destination_service_namespace":"istio-system","destination_version":"unknown","destination_workload":"istio-telemetry","destination_workload_namespace":"istio-system","instance":"10.244.1.6:42422","job":"istio-mesh","permissive_response_code":"none","permissive_response_policyid":"none","reporter":"destination","request_protocol":"grpc","response_code":"200","response_flags":"-","source_app":"sleep","source_principal":"unknown","source_version":"unknown","source_workload":"sleep","source_workload_namespace":"samples"},"values":[[1575534806,"3"],[1575534820,"3"],[1575534834,"3"],[1575534848,"3"],[1575534862,"3"],[1575534876,"3"],[1575534890,"3"],[1575534904,"3"],[1575534918,"3"],[1575534932,"3"],[1575534946,"3"],[1575534960,"3"],[1575534974,"3"],[1575534988,"3"],[1575535002,"3"],[1575535016,"3"],[1575535030,"3"],[1575535044,"3"],[1575535058,"3"],[1575535072,"3"],[1575535086,"3"],[1575535100,"3"],[1575535114,"3"],[1575535128,"3"],[1575535142,"3"],[1575535156,"3"],[1575535170,"3"]]},{"metric":{"__name__":"istio_requests_total","connection_security_policy":"unknown","destination_app":"httpbin","destination_principal":"unknown","destination_service":"httpbin.samples.svc.cluster.local","destination_service_name":"httpbin","destination_service_namespace":"samples","destination_version":"v1","destination_workload":"httpbin","destination_workload_namespace":"samples","instance":"10.244.1.6:42422","job":"istio-mesh","permissive_response_code":"none","permissive_response_policyid":"none","reporter":"source","request_protocol":"http","response_code":"200","response_flags":"-","source_app":"sleep","source_principal":"unknown","source_version":"unknown","source_workload":"sleep","source_workload_namespace":"samples"},"values":[[1575534806,"3"],[1575534820,"3"],[1575534834,"3"],[1575534848,"3"],[1575534862,"3"],[1575534876,"3"],[1575534890,"3"],[1575534904,"3"],[1575534918,"3"],[1575534932,"3"],[1575534946,"3"],[1575534960,"3"],[1575534974,"3"],[1575534988,"3"],[1575535002,"3"],[1575535016,"3"],[1575535030,"3"],[1575535044,"3"],[1575535058,"3"],[1575535072,"3"],[1575535086,"3"],[1575535100,"3"],[1575535114,"3"],[1575535128,"3"],[1575535142,"3"],[1575535156,"3"],[1575535170,"3"]]}]}}
```
