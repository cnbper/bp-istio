# kiali develop

## 配置开发环境

```shell
cd ${GOPATH}/src/github.com/kiali/kiali

# 转换为go mod 项目
go mod init

cd ../kiali-ui
npm install -g yarn
yarn
yarn start
yarn build
```

```shell
glide mirror set https://k8s.io/client-go https://github.com/kubernetes/client-go --vcs git
glide mirror set https://k8s.io/apimachinery https://github.com/kubernetes/apimachinery --vcs git
glide mirror set https://k8s.io/kube-openapi https://github.com/kubernetes/kube-openapi --vcs git
glide mirror set https://k8s.io/api https://github.com/kubernetes/api/batch/v1 --vcs git
glide mirror set https://golang.org/x/net https://github.com/golang/net --vcs git
glide mirror set https://golang.org/x/crypto https://github.com/golang/crypto --vcs git
glide mirror set https://golang.org/x/time https://github.com/golang/time --vcs git

glide update
```
