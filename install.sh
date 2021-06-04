#!/usr/bin/env bash
# change time zone
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai
rm /etc/yum.repos.d/CentOS-Base.repo
cp /vagrant/yum/*.* /etc/yum.repos.d/
mv /etc/yum.repos.d/CentOS7-Base-163.repo /etc/yum.repos.d/CentOS-Base.repo
# using socat to port forward in helm tiller
# install  kmod and ceph-common for rook
yum install -y wget curl conntrack-tools vim net-tools telnet tcpdump bind-utils socat ntp kmod ceph-common dos2unix
kubernetes_release="/vagrant/kubernetes-server-linux-amd64.tar.gz"
# Download Kubernetes
if [[ $(hostname) == "node1" ]] && [[ ! -f "$kubernetes_release" ]]; then
    wget https://storage.googleapis.com/kubernetes-release/release/v1.16.14/kubernetes-server-linux-amd64.tar.gz -P /vagrant/
fi

# enable ntp to sync time
echo 'sync time'
systemctl start ntpd
systemctl enable ntpd
echo 'disable selinux'
setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

echo 'enable iptable kernel parameter'
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
EOF
sysctl -p

echo 'set host name resolution'
cat >> /etc/hosts <<EOF
172.17.8.101 node1
172.17.8.102 node2
172.17.8.103 node3
EOF

cat /etc/hosts

echo 'set nameserver'
echo "nameserver 8.8.8.8">/etc/resolv.conf
cat /etc/resolv.conf

echo 'disable swap'
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

#create group if not exists
egrep "^docker" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
  groupadd docker
fi

usermod -aG docker vagrant
rm -rf ~/.docker/
yum install -y docker.x86_64
# To fix docker exec error, downgrade docker version, see https://github.com/openshift/origin/issues/21590
yum downgrade -y docker-1.13.1-75.git8633870.el7.centos.x86_64 docker-client-1.13.1-75.git8633870.el7.centos.x86_64 docker-common-1.13.1-75.git8633870.el7.centos.x86_64

cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors" : [
	"https://reg-mirror.qiniu.com",
	"https://hub-mirror.c.163.com",
	"https://mirror.ccs.tencentyun.com",
	"https://docker.mirrors.ustc.edu.cn",
	"https://dockerhub.azk8s.cn",
	"https://registry.docker-cn.com"
  ]
}
EOF

if [[ $1 -eq 1 ]]
then
    yum install -y etcd
    #cp /vagrant/systemd/etcd.service /usr/lib/systemd/system/
cat > /etc/etcd/etcd.conf <<EOF
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://$2:2380"
ETCD_LISTEN_CLIENT_URLS="http://$2:2379,http://localhost:2379"
ETCD_NAME="node$1"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$2:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://$2:2379"
ETCD_INITIAL_CLUSTER="$3"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF
    cat /etc/etcd/etcd.conf
    echo 'create network config in etcd'
cat > /etc/etcd/etcd-init.sh<<EOF
#!/bin/bash
etcdctl mkdir /kube-centos/network
etcdctl mk /kube-centos/network/config '{"Network":"172.33.0.0/16","SubnetLen":24,"Backend":{"Type":"host-gw"}}'
EOF
    chmod +x /etc/etcd/etcd-init.sh
    echo 'start etcd...'
    systemctl daemon-reload
    systemctl enable etcd
    systemctl start etcd

    echo 'create kubernetes ip range for flannel on 172.33.0.0/16'
    /etc/etcd/etcd-init.sh
    etcdctl cluster-health
    etcdctl ls /
fi

echo 'install flannel...'
yum install -y flannel

echo 'create flannel config file...'

cat > /etc/sysconfig/flanneld <<EOF
# Flanneld configuration options
FLANNEL_ETCD_ENDPOINTS="http://172.17.8.101:2379"
FLANNEL_ETCD_PREFIX="/kube-centos/network"
FLANNEL_OPTIONS="-iface=eth1"
EOF

echo 'enable flannel with host-gw backend'
rm -rf /run/flannel/
systemctl daemon-reload
systemctl enable flanneld
systemctl start flanneld

echo 'enable docker'
systemctl daemon-reload
systemctl enable docker
systemctl start docker

echo "copy pem, token files"
mkdir -p /etc/kubernetes/ssl
cp /vagrant/pki/* /etc/kubernetes/ssl/
cp /vagrant/conf/token.csv /etc/kubernetes/
cp /vagrant/conf/bootstrap.kubeconfig /etc/kubernetes/
cp /vagrant/conf/kube-proxy.kubeconfig /etc/kubernetes/
cp /vagrant/conf/kubelet.kubeconfig /etc/kubernetes/

tar -xzvf /vagrant/kubernetes-server-linux-amd64.tar.gz --no-same-owner -C /vagrant
cp /vagrant/kubernetes/server/bin/* /usr/bin

dos2unix -q /vagrant/systemd/*.service
cp /vagrant/systemd/*.service /usr/lib/systemd/system/
mkdir -p /var/lib/kubelet
mkdir -p ~/.kube
cp /vagrant/conf/admin.kubeconfig ~/.kube/config

if [[ $1 -eq 1 ]]
then
    echo "configure master and node1"

    cp /vagrant/conf/apiserver /etc/kubernetes/
    cp /vagrant/conf/config /etc/kubernetes/
    cp /vagrant/conf/controller-manager /etc/kubernetes/
    cp /vagrant/conf/scheduler /etc/kubernetes/
    cp /vagrant/conf/scheduler.conf /etc/kubernetes/
    cp /vagrant/node1/* /etc/kubernetes/

    systemctl daemon-reload
    systemctl enable kube-apiserver
    systemctl start kube-apiserver

    systemctl enable kube-controller-manager
    systemctl start kube-controller-manager

    systemctl enable kube-scheduler
    systemctl start kube-scheduler

    systemctl enable kubelet
    systemctl start kubelet

    systemctl enable kube-proxy
    systemctl start kube-proxy
fi

if [[ $1 -eq 2 ]]
then
    echo "configure node2"
    cp /vagrant/node2/* /etc/kubernetes/

    systemctl daemon-reload
    systemctl enable kubelet
    systemctl start kubelet
    systemctl enable kube-proxy
    systemctl start kube-proxy
fi

if [[ $1 -eq 3 ]]
then
    echo "configure node3"
    cp /vagrant/node3/* /etc/kubernetes/

    systemctl daemon-reload

    systemctl enable kubelet
    systemctl start kubelet
    systemctl enable kube-proxy
    systemctl start kube-proxy

    echo "deploy coredns"
    cd /vagrant/addon/dns/
    ./dns-deploy.sh -r 10.254.0.0/16 -i 10.254.0.2 |kubectl apply -f -
    cd -

    echo "deploy kubernetes dashboard"
    kubectl apply -f /vagrant/addon/dashboard/kubernetes-dashboard.yaml
    echo "create admin role token"
    kubectl apply -f /vagrant/yaml/admin-role.yaml
    echo "the admin role token is:"
    kubectl -n kube-system describe secret `kubectl -n kube-system get secret|grep admin-token|cut -d " " -f1`|grep "token:"|tr -s " "|cut -d " " -f2
    echo "login to dashboard with the above token"
    echo https://172.17.8.101:`kubectl -n kube-system get svc kubernetes-dashboard -o=jsonpath='{.spec.ports[0].port}'`
    echo "install traefik ingress controller"
    kubectl apply -f /vagrant/addon/traefik-ingress/
fi

echo "Configure Kubectl to autocomplete"
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.

