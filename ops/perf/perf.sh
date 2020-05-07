#!/bin/bash
for i in {1..50}
do
    namespace=perf-${i}

    kubectl create ns "${namespace}" || true
    kubectl label namespace "${namespace}" istio-injection=enabled --overwrite

    for j in {1..20}
    do

    app=${namespace}-ms-${j}

cat <<EOF | kubectl -n ${namespace} apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${app}
  labels:
    app: ${app}
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: ${app}

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${app}-conf
  labels:
    app: ${app}
data:
  app.properties: |-
    {
        "appId":"smp-config-demo${i}",
        "cluster":"default",
        "namespaceNames":["application"],
        "ip":"http://configcenter-config-core.ns-team-2-env-1:8080"
    }

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${app}
  template:
    metadata:
      labels:
        app: ${app}
    spec:
      containers:
      - name: app
        image: harbor.uat.cmft.com/cmft-ipaas/apollo-demo:v1
        imagePullPolicy: Always
        env:
        - name: configFilePath
          value: /root/conf/app.properties
        volumeMounts:
        - name: config-volume
          mountPath: /root/conf
      volumes:
      - name: config-volume
        configMap:
          name: ${app}-conf
EOF

    done

done