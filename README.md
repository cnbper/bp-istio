# istio

<https://istio.io>

## 初始化工作目录

```shell
mkdir -p temp

# 注意调整istio版本
IstioCurVersion=istio-1.3.8
# IstioCurVersion=istio-1.5.2
tar zxvf $IstioCurVersion-osx.tar.gz -C temp
rm -rf istio-release/*
mv temp/$IstioCurVersion/* istio-release

cp istio-release/bin/istioctl ../kubernetes-vagrant-centos-cluster/bin/istioctl
sudo cp istio-release/bin/istioctl /usr/local/bin/istioctl

# 删除 yaml 文件
rm -rf yaml/*
```

## helm安装

### windows

<https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-windows-amd64.zip>

配置环境变量

- D:\software\helm-v2.13.1-windows-amd64

### mac

- /usr/local/bin/helm

### linux

<https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz>
