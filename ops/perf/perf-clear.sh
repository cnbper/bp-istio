#!/bin/bash
for i in {1..50}
do
    namespace=perf-${i}

    kubectl delete ns "${namespace}" || true

done