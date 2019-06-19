# istio

<https://istio.io>

## 初始化工作目录

```shell
mkdir -p temp

# 注意调整istio版本
IstioCurVersion=istio-1.2.0-rc.3
tar zxvf $IstioCurVersion-osx.tar.gz -C temp
rm -rf istio-release/*
mv temp/$IstioCurVersion/* istio-release

cp istio-release/bin/istioctl ../kubernetes-vagrant-centos-cluster/bin/istioctl
sudo cp istio-release/bin/istioctl /usr/local/bin/istioctl

cat istio-release/install/kubernetes/helm/istio/charts/kiali/values.yaml | grep tag
# 升级 kiali 到 v0.20
rm -rf rm -rf istio-release/install/kubernetes/helm/istio/charts/kiali
cp -r $GOPATH/src/istio.io/istio/install/kubernetes/helm/istio/charts/kiali istio-release/install/kubernetes/helm/istio/charts/kiali
```

## helm安装

### windows

<https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-windows-amd64.zip>

配置环境变量

- D:\software\helm-v2.13.1-windows-amd64

### mac

TODO

### linux

<https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz>
