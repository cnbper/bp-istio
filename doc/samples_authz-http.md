# HTTP 服务的访问控制

<https://istio.io/docs/tasks/security/authz-http/>

Istio 采用基于角色(RBAC)的访问控制方式，本文内容涵盖了为 HTTP 设置访问控制的各个环节。

## 前提条件

- 安装了 Istio 并启用认证功能
- 部署 Bookinfo 示例应用

- 这一任务中，借助 Service Account 在网格中提供加密的访问控制能力。为了给不同的微服务赋予不同的访问权限，就需要创建一些 Service Account 用来运行 Bookinfo 中的微服务。
  - 创建 Service Account bookinfo-productpage，并用这一身份重新部署 productpage 微服务。
  - 创建 Service Account bookinfo-reviews，并用它来重新部署 reviews（reviews-v2 和 reviews-v3 两个 Deployment）。

```shell
# 注意调整镜像地址
kubectl -n istio-samples apply -f <(istioctl kube-inject -f istio-release/samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml)

# 测试
kubectl -n istio-samples get pods
```

## 启用 Istio 访问控制

```shell
# 调整文件内容 修改 default 为 istio-samples
sed -i '' 's/"default"/"istio-samples"/g' istio-release/samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml

kubectl apply -f istio-release/samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml
```

ClusterRbacConfig 中 mode 枚举值

- OFF：禁用 Istio 授权。
- ON：为网格中的所有服务启用了 Istio 授权。
- ON_WITH_INCLUSION：仅对包含字段中指定的服务和命名空间启用 Istio 授权。
- ON_WITH_EXCLUSION：除了排除字段中指定的服务和命名空间外，网格中的所有服务都启用了 Istio 授权。

用浏览器打开 Bookinfo productpage（http://172.17.8.101:31380/productpage）。应该会看到 "RBAC: access denied"，原因是 Istio 访问控制缺省采用拒绝策略，这就要求必须显式的声明访问控制策略才能成功的访问到服务。**注意：缓存或者其它传播开销可能会造成生效延迟。**

## 命名空间级别的访问控制

使用 Istio 能够轻松的在命名空间一级设置访问控制，只要设置命名空间中所有（或部分）服务可以被其它命名空间的服务访问即可。

Bookinfo 案例中，productpage、reviews、details 和 ratings 服务都部署在 default 命名空间之内。而 istio-ingressgateway 这样的 Istio 组件是部署在 istio-system 命名空间内的。可以定义一个策略，default 命名空间内的服务如果它的 app 标签值属于 productpage、reviews、details 和 ratings 其中的一个，就可以被同一命名空间（default）内的服务访问。

```shell
# 调整文件内容 修改 default 为 istio-samples
sed -i '' 's/default/istio-samples/g' istio-release/samples/bookinfo/platform/kube/rbac/namespace-policy.yaml

kubectl -n istio-samples apply -f istio-release/samples/bookinfo/platform/kube/rbac/namespace-policy.yaml
```

如果用浏览器访问 Bookinfo productpage（http://172.17.8.101:31380/productpage），应该会看到 “Bookinfo Sample” 页面，左下角是 “Book Details”，右下角是 “Book Reviews”。

清除数据

```shell
kubectl -n istio-samples delete -f istio-release/samples/bookinfo/platform/kube/rbac/namespace-policy.yaml
```

## 服务级访问控制

- 开放到 productpage 服务的访问

```shell
# 调整文件内容 修改 default 为 istio-samples
sed -i '' 's/default/istio-samples/g' istio-release/samples/bookinfo/platform/kube/rbac/productpage-policy.yaml

kubectl apply -f istio-release/samples/bookinfo/platform/kube/rbac/productpage-policy.yaml
```

用浏览器访问 Bookinfo productpage（http://172.17.8.101:31380/productpage），现在应该就能看到 “Bookinfo Sample” 页面了，但是页面上会显示 Error fetching product details and Error fetching product reviews 的错误信息。这些错误信息是正常的，原因是 productpage 还无权访问 details 和 reviews 服务。

- 开放到 details 和 reviews 服务的访问

```shell
# 调整文件内容 修改 default 为 istio-samples
sed -i '' 's/default/istio-samples/g' istio-release/samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml

kubectl apply -f istio-release/samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml
```

浏览器打开 Bookinfo productpage（http://172.17.8.101:31380/productpage），现在应该就能看到 “Bookinfo Sample” 页面中，在左下方显示了 “Book Details”，在右下方显示了 “Book Reviews”。然而 “Book Reviews” 部分显示了一个错误信息：Ratings service currently unavailable，错误的原因是 reviews 服务无权访问 ratings 服务。要解决这一问题，就需要授权给 reviews 服务，允许它访问 ratings 服务。

- 开放访问 ratings 服务

```shell
# 调整文件内容 修改 default 为 istio-samples
sed -i '' 's/default/istio-samples/g' istio-release/samples/bookinfo/platform/kube/rbac/ratings-policy.yaml

kubectl apply -f istio-release/samples/bookinfo/platform/kube/rbac/ratings-policy.yaml
```

用浏览器访问 Bookinfo productpage（http://172.17.8.101:31380/productpage）。现在应该能在 “Book Reviews” 中看到黑色或红色的星级图标。

## 清除数据

```shell
kubectl delete -f istio-release/samples/bookinfo/platform/kube/rbac/ratings-policy.yaml
kubectl delete -f istio-release/samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml
kubectl delete -f istio-release/samples/bookinfo/platform/kube/rbac/productpage-policy.yaml

kubectl delete servicerole --all
kubectl delete servicerolebinding --all

kubectl delete -f istio-release/samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml
```
