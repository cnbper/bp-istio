# istio develop

<https://github.com/istio/istio/wiki/Preparing-for-Development>
<https://github.com/istio/istio/wiki/Using-the-Code-Base>

## 配置开发环境

- 配置 GO 环境
- 配置 docker 环境
- 配置 fpm <https://fpm.readthedocs.io/en/latest/installing.html>

```shell
brew install ruby
brew install gnu-tar

sudo gem install --no-document fpm

fpm --version
```

## istio.io/istio

```shell
# 下载依赖
GO111MODULE=on go mod download
GO111MODULE=on go mod vendor

# 构建kubectl镜像时，远程下载调整为本地缓存
# ADD https://storage.googleapis.com/kubernetes-release/release/v1.13.10/bin/linux/amd64/kubectl /usr/bin/kubectl
mkdir -p /Users/zhangbaohao/software/golang/workspace/out/linux_amd64/release/docker_build/docker.kubectl
wget -P /Users/zhangbaohao/software/golang/workspace/out/linux_amd64/release/docker_build/docker.kubectl https://storage.googleapis.com/kubernetes-release/release/v1.13.10/bin/linux/amd64/kubectl
vi docker/Dockerfile.kubectl
# 基础镜像准备 gcr.io/distroless/static:latest
docker pull cistio/distroless-static:latest
docker tag cistio/distroless-static:latest gcr.io/distroless/static:latest
docker rmi cistio/distroless-static:latest
# 基础镜像准备 gcr.io/distroless/cc:latest
docker pull cistio/distroless-cc:latest
docker tag cistio/distroless-cc:latest gcr.io/distroless/cc:latest
docker rmi cistio/distroless-cc:latest

make init # 初始化，检查目录结构、Go版本号、初始化环境变量、检查vendor等

cat > .env<<EOF
export HUB=registry.sloth.com/ipaas
export TAG=1.4.2-dev
EOF
source .env

make build # 编译
make pilot-agent

make docker # 构建镜像
make docker.push # 构建镜像并到dockerhub

GOOS=linux make build docker.push # 编译+构建镜像+推送
GOOS=linux make pilot push.docker.pilot # 编译pilot组件和镜像并推送

# 依赖envoy
GOOS=linux make pilot-agent push.docker.proxyv2 # 编译proxyv2组件和镜像并推送
```

## sidecar-injector

- 源码入口 istio/pilot/cmd/sidecar-injector

```shell
```

## galley

```shell
# 基于serviceaccount生成配置
kubectl -n istio-system apply -f yaml/istio-galley.yaml
kubectl -n istio-system get sa  istio-galley-service-account  -o yaml
kubectl -n istio-system get secret istio-galley-service-account-token-6n42r -o yaml
```

## pilot

- pilot/cmd/pilot-discovery/main.go

```shell
# 下载依赖
go mod download

# 帮助
pilot-discovery help
# 查看版本
pilot-discovery version
# 查看版本
pilot-discovery discovery -h
```

- pilot-discovery discovery [flags]

```shell
Flags:
  -a, --appNamespace string                 Restrict the applications namespace the controller manages; if not set, controller watches all namespaces
      --clusterRegistriesNamespace string   Namespace for ConfigMap which stores clusters configs
      --configDir string                    Directory to watch for updates to config yaml files. If specified, the files will be used as the source of config, rather than a CRD client.
      --consulserverInterval duration       Interval (in seconds) for polling the Consul service registry (default 2s)
      --consulserverURL string              URL for the Consul server
      --disable-install-crds                Disable discovery service from verifying the existence of CRDs at startup and then installing if not detected.  It is recommended to be disable for highly available setups.
      --discoveryCache                      Enable caching discovery service responses (default true)
      --domain string                       DNS domain suffix (default "cluster.local")
      --grpcAddr string                     Discovery service grpc address (default ":15010")
  -h, --help                                help for discovery
      --httpAddr string                     Discovery service HTTP address (default ":8080")
      --kubeconfig string                   Use a Kubernetes configuration file instead of in-cluster configuration
      --mcpInitialConnWindowSize int        Initial connection window size for MCP's gRPC connection (default 1048576)
      --mcpInitialWindowSize int            Initial window size for MCP's gRPC connection (default 1048576)
      --mcpMaxMsgSize int                   Max message size received by MCP's grpc client (default 4194304)
      --meshConfig string                   File name for Istio mesh configuration. If not specified, a default mesh will be used. (default "/etc/istio/config/mesh")
      --monitoringAddr string               HTTP address to use for pilot's self-monitoring information (default ":15014")
  -n, --namespace string                    Select a namespace where the controller resides. If not set, uses ${POD_NAMESPACE} environment variable
      --networksConfig string               File name for Istio mesh networks configuration. If not specified, a default mesh networks will be used. (default "/etc/istio/config/meshNetworks")
      --plugins strings                     comma separated list of networking plugins to enable (default [authn,authz,health,mixer])
      --profile                             Enable profiling via web interface host:port/debug/pprof (default true)
      --registries strings                  Comma separated list of platform service registries to read from (choose one or more from {Kubernetes, Consul, MCP, Mock}) (default [Kubernetes])
      --resync duration                     Controller resync interval (default 1m0s)
      --secureGrpcAddr string               Discovery service grpc address, with https (default ":15012")
      --trust-domain string                 The domain serves to identify the system with spiffe

Global Flags:
      --ctrlz_address string                       The IP Address to listen on for the ControlZ introspection facility. Use '*' to indicate all addresses. (default "localhost")
      --ctrlz_port uint16                          The IP port to use for the ControlZ introspection facility (default 9876)
      --keepaliveInterval duration                 The time interval if no activity on the connection it pings the peer to see if the transport is alive (default 30s)
      --keepaliveMaxServerConnectionAge duration   Maximum duration a connection will be kept open on the server before a graceful close. (default 2562047h47m16.854775807s)
      --keepaliveTimeout duration                  After having pinged for keepalive check, the client/server waits for a duration of keepaliveTimeout and if no activity is seen even after that the connection is closed. (default 10s)
      --log_as_json                                Whether to format output as JSON or in plain console-friendly format
      --log_caller string                          Comma-separated list of scopes for which to include caller information, scopes can be any of [ads, all, authn, default, mcp, model, rbac]
      --log_output_level string                    Comma-separated minimum per-scope logging level of messages to output, in the form of <scope>:<level>,<scope>:<level>,... where scope can be one of [ads, all, authn, default, mcp, model, rbac] and level can be one of [debug, info, warn, error, fatal, none] (default "default:info")
      --log_rotate string                          The path for the optional rotating log file
      --log_rotate_max_age int                     The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit) (default 30)
      --log_rotate_max_backups int                 The maximum number of log file backups to keep before older files are deleted (0 indicates no limit) (default 1000)
      --log_rotate_max_size int                    The maximum size in megabytes of a log file beyond which the file is rotated (default 104857600)
      --log_stacktrace_level string                Comma-separated minimum per-scope logging level at which stack traces are captured, in the form of <scope>:<level>,<scope:level>,... where scope can be one of [ads, all, authn, default, mcp, model, rbac] and level can be one of [debug, info, warn, error, fatal, none] (default "default:none")
      --log_target stringArray                     The set of paths where to output the log. This can be any path as well as the special values stdout and stderr (default [stdout])

```

```shell
--monitoringAddr=:15014
--log_output_level=default:info
--domain=cluster.local
--secureGrpcAddr=""
--keepaliveMaxServerConnectionAge="30m"
--meshConfig="/Users/zhangbaohao/software/golang/workspace/src/istio.io/local/istio/config/mesh"
--networksConfig="/Users/zhangbaohao/software/golang/workspace/src/istio.io/local/istio/config/meshNetworks"
```

## 配置开发环境



## 下载依赖

```shell

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
