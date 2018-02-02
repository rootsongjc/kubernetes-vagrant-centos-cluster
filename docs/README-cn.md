# 使用Vagrant和Virtualbox搭建Kubernetes集群

当我们需要在本地开发时，更希望能够有一个开箱即用又可以方便定制的分布式开发环境，这样才能对Kubernetes本身和应用进行更好的测试。现在我们使用[Vagrant](https://www.vagrantup.com/)和[VirtualBox](https://www.virtualbox.org/wiki/Downloads)来创建一个这样的环境。

## 准备环境

需要准备以下软件和环境：

- 8G以上内存
- Vagrant 2.0+
- Virtualbox 5.0 +
- 提前下载kubernetes的release压缩包

## 集群

我们使用Vagrant和Virtualbox安装包含3个节点的kubernetes集群，其中master节点同时作为node节点。

| IP           | 主机名   | 组件                                       |
| ------------ | ----- | ---------------------------------------- |
| 172.17.8.101 | node1 | kube-apiserver、kube-controller-manager、kube-scheduler、etcd、kubelet、docker、flannel |
| 172.17.8.102 | node2 | kubelet、docker、flannel                   |
| 172.17.8.103 | node3 | kubelet、docker、flannel                   |

**注意**：以上的IP、主机名和组件都是固定在这些节点的，即使销毁后下次使用vagrant重建依然保持不变。

容器IP范围：172.33.0.0/30

Kubernetes service IP范围：10.254.0.0/16

## 安装的组件

安装完成后的集群包含以下组件：

- flannel（`host-gw`模式）
- kubernetes dashboard 1.8.2
- etcd（单节点）
- kubectl
- kubernetes（版本根据下载的kubernetes安装包而定）

## 部署

确保安装好以上的准备环境后，执行下列命令启动kubernetes集群：

```bash
git clone https://github.com/rootsongjc/kubernetes-vagrant-centos-cluster.git
cd kubernetes-vagrant-centos-cluster
vagrant up
```

**注意**：克隆完Git仓库后，需要提前下载kubernetes的压缩包到`kubenetes-vagrant-centos-cluster`目录下，包括如下两个文件：

- kubernetes-client-linux-amd64.tar.gz
- kubernetes-server-linux-amd64.tar.gz

如果是首次部署，会自动下载`centos/7`的box，这需要花费一些时间，另外每个节点还需要下载安装一系列软件包，整个过程大概需要10几分钟。

## 访问kubernetes集群

```bash
vagrant ssh node1
kubectl get nodes
```

## 清理

```bash
vagrant destroy
rm -rf .vagrant
```

## 参考

- [Kubernetes handbook - jimmysong.io](https://jimmysong.io/kubernetes-handbook)
- [duffqiu/centos-vagrant](https://github.com/duffqiu/centos-vagrant)