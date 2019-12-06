# docker

```shell script
# 删除临时文件
docker image prune

tag=1.3.4-dev
docker images | grep $tag | awk '{print $1}' | xargs -I {} docker rmi {}:$tag

docker images | grep none | awk '{print $3}' | xargs docker rmi
```
