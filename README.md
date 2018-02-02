# Setting up a kubernetes cluster with Vagrant and Virtualbox

# 使用Vagrant和Virtualbox搭建Kubernetes集群

[中文](docs/README-cn.md)


Using vagrant file to build a kubernetes cluster which consists of 1 master(also as node) and 3 nodes. You don't have to create complicated ca files or configuration.

### Why don't do that with kubeadm

Because I want to setup the etcd, apiserver, controller, scheduler without docker container.

### Architecture

We will create a Kubernetes cluster with 3 nodes which contains the components below:

| IP           | Hostname | Componets                                |
| ------------ | -------- | ---------------------------------------- |
| 172.17.8.101 | node1    | kube-apiserver, kube-controller-manager, kube-scheduler, etcd, kubelet, docker, flannel |
| 172.17.8.102 | node2    | kubelet, docker, flannel                 |
| 172.17.8.103 | node3    | kubelet, docker, flannel                 |

The default setting will create the private network from 172.17.8.101 to 172.17.8.103 for nodes, and it will use the host's DHCP for the public ip.

The kubernetes service's vip range is `10.254.0.0/16`.

The container network range is `170.33.0.0/16` owned by flanneld with `host-gw` backend.

### Usage

#### Prerequisite
* Host server with 8G+ mem(More is better), 60G disk, 8 core cpu at lease
* vagrant 2.0+
* virtualbox 5.0+
* Maybe need to access the internet through GFW to download the kubernetes files

### Support Addon

- CoreDNS
- Dashboard

#### Setup
```bash
git clone https://github.com/rootsongjc/kubernetes-vagrant-centos-cluster.git
cd kubernetes-vagrant-centos-cluster
vagrant up
```

Wait about 10 minutes the kubernetes cluster will be setup automatically.

#### Connect to kubernetes cluster

There are 3 ways to access the kubernetes cluster.

**local**

Copy `conf/admin.kubeconfig` to `～/.kube/config`, using `kubectl` CLI to access the cluster.

We recommend this way.

**VM**

Login to the virtual machine to access and debug the cluster.

```bash
vagrant ssh node1
kubectl get nodes
```

**dashbaord**

Through the kubernetes dashboard to access the cluster.

URL

https://172.17.8.101

Port

```bash
kubectl -n kube-system get svc kubernetes-dashboard -o=jsonpath='{.spec.ports[0].nodePort}'
```

token

```bash
kubectl -n kube-system describe secret `kubectl -n kube-system get secret|grep admin-token|cut -d " " -f1`|grep "token:"|tr -s " "|cut -d " " -f2
```

Using `URL:Port` to access the cluster and input the token to login.

#### Clean

```bash
vagrant destroy
rm -rf .vagrant
```

#### Note

Don't use it in production environment.

#### Reference

* [Kubernetes Handbook - jimmysong.io](https://jimmysong.io/kubernetes-handbook/)
* [duffqiu/centos-vagrant](https://github.com/duffqiu/centos-vagrant)
