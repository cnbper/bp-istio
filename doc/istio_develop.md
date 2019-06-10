# istio develop

## 配置开发环境

- 配置 GO 环境
- 配置 docker 环境
- 配置 fpm <https://fpm.readthedocs.io/en/latest/installing.html>

```shell
brew install gnu-tar

sudo gem install --no-ri --no-rdoc fpm

fpm --version
```

## 下载依赖

```shell
GO111MODULE=on go mod download

make init # 初始化，检查目录结构、Go版本号、初始化环境变量、检查vendor等
make docker # 对各组件（istioctl、mixer、pilot、istio-auth等）进行二进制包编译、测试、镜像编译
make push # 推送镜像到dockerhub

# 其他指令
make pilot  docker.pilot # 编译pilot组件和镜像
make app  docker.app # 编译app组件和镜像
make proxy  docker.proxy # 编译proxy组件和镜像
make proxy_init  docker.proxy_init # 编译proxy_init组件和镜像
make proxy_debug  docker.proxy_debug # 编译proxy_debug组件和镜像
make sidecar_injector  docker.sidecar_injector # 编译sidecar_injector组件和镜像
make proxyv2  docker.proxyv2 # 编译proxyv2组件和镜像

make push.docker.pilot # 推送pilot镜像到dockerhub，其他组件类似

cd $GOPATH/src/istio.io/istio

./bin/get_workspace_status # 查看当前工作目录状态，包括环境变量等
install/updateVersion.sh -a ${HUB},${TAG} # 使用当前环境变量生成Istio清单
samples/bookinfo/build_push_update_images.sh # 使用当前环境变量编译并推送bookinfo镜像
```
