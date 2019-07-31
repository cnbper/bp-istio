# dotnet

## 环境搭建

- 下载 [.NET Core 2.2 SDK](https://dotnet.microsoft.com/download)
- 安装 .NET Core 2.2 SDK
- 配置环境变量

```shell
cat >> ~/.bash_profile<< EOF
export PATH=$PATH:/usr/local/share/dotnet
EOF
source ~/.bash_profile
```

- 测试

```shell
# 测试
dotnet --info
```

## 初始化项目

```shell
mkdir docker-working && cd docker-working

# 创建 global.json
cat > global.json<<EOF
{
  "sdk": {
    "version": "`dotnet --version`"
  }
}
EOF

# 初始化 app
dotnet new console -o app -n myapp

# 测试运行
cd app && dotnet run
```

## 发布项目

```shell
dotnet publish -c Release
```

## 容器化

<https://docs.microsoft.com/en-us/dotnet/core/docker/build-container>

```shell
cd docker-working

cat > Dockerfile<<EOF
FROM mcr.microsoft.com/dotnet/core/runtime:2.2

COPY app/bin/Release/netcoreapp2.2/publish/ app/

ENTRYPOINT ["dotnet", "app/myapp.dll"]
EOF

docker build -t myimage -f Dockerfile .

docker images | grep myimage
```

```shell
docker create --name myimage myimage

docker start myimage
docker stop myimage
docker rm myimage

docker attach --sig-proxy=false myimage
```

```shell
docker run -it --rm --entrypoint "bash" myimage
```

## 创建 Web API 应用

<https://docs.microsoft.com/en-us/aspnet/core/tutorials/first-web-api?view=aspnetcore-2.2>

```shell
cd docker-working

dotnet new webapi -o TodoApi

cd TodoApi && dotnet run

https://localhost:5001/api/values
https://localhost:5001/api/todo
https://localhost:5001/api/todo/1

dotnet publish -c Release

cat > Dockerfile<<EOF
FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-stretch-slim

COPY bin/Release/netcoreapp2.2/publish/ app/

ENTRYPOINT ["dotnet", "app/TodoApi.dll"]
EOF

docker build -t todo-api -f Dockerfile .

docker run -it --rm -p 8080:80 todo-api

http://localhost:8080/api/values
http://localhost:8080/api/todo
http://localhost:8080/api/todo/1
```

```shell
cd docker-working && dotnet new webapi -o OrderApi

cd OrderApi && dotnet run

https://localhost:5001/api/values
https://localhost:5001/api/order
https://localhost:5001/api/order/1

dotnet publish -c Release

cat > Dockerfile<<EOF
FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-stretch-slim AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:2.2-stretch AS build
WORKDIR /src
COPY OrderApi.csproj OrderApi/
RUN dotnet restore OrderApi/OrderApi.csproj
COPY . OrderApi/
WORKDIR /src/OrderApi
RUN dotnet build OrderApi.csproj -c Release -o /app

FROM build AS publish
RUN dotnet publish OrderApi.csproj -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "OrderApi.dll"]
EOF

docker build -t order-api -f Dockerfile .

docker tag order-api registry.sloth.com/istio-demo/order-api
docker push registry.sloth.com/istio-demo/order-api

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: istio-demo
 labels:
    istio-injection: enabled
EOF

cat <<EOF | kubectl -n istio-demo apply -f -
apiVersion: v1
kind: Service
metadata:
  name: order-api
  labels:
    app: order-api
    service: order-api
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: order-api
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-api-v1
  labels:
    app: order-api
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-api
      version: v1
  template:
    metadata:
      labels:
        app: order-api
        version: v1
    spec:
      containers:
      - name: order-api
        image: registry.sloth.com/istio-demo/order-api
        imagePullPolicy: Always
        ports:
        - containerPort: 80
EOF

cat <<EOF | kubectl -n istio-demo apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: order-api
spec:
  rules:
  - host: order.sloth.com
    http:
      paths:
      - path: /
        backend:
          serviceName: order-api
          servicePort: http
EOF

http://order.sloth.com/api/values
http://order.sloth.com/api/order

kubectl -n istio-demo get pod -o wide

docker run -it --rm -p 8080:80 registry.sloth.com/istio-demo/order-api

http://localhost:8080/api/values
http://localhost:8080/api/order
http://localhost:8080/api/order/1
```
