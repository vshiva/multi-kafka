# multi-kafka

A Kafka setup for running integration tests against kafka in kubernetes cluster

for deploying

#### pre-req

- [kustomize]
- [kubectl]
- And a K8s Cluster

Easiest way to get one is if you already have [go] and [docker]

```shell
go get -u sigs.k8s.io/kind
kind create cluster
```

```shell
kustomize build ./deployment | kubectl apply -f -
```

<!--links-->
[go]: https://golang.org/
[docker]: https://www.docker.com/
[kustomize]: https://github.com/kubernetes-sigs/kustomize
[kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl