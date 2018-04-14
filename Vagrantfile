# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  #config.vm.box = "centos/7"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = false

  # Sync time with the local host
  config.vm.provider 'virtualbox' do |vb|
   vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
  end

  $num_instances = 3

  # curl https://discovery.etcd.io/new?size=3
  $etcd_cluster = "node1=http://172.17.8.101:2380"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  (1..$num_instances).each do |i|

    config.vm.define "node#{i}" do |node|
    node.vm.box = "centos/7"
    node.vm.hostname = "node#{i}"
    ip = "172.17.8.#{i+100}"
    node.vm.network "private_network", ip: ip
    node.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)", auto_config: true
    #node.vm.synced_folder "/Users/DuffQiu/share", "/home/vagrant/share"

    node.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
      vb.memory = "3072"
      vb.cpus = 1
      vb.name = "node#{i}"
    end

    node.vm.provision "shell" do |s|
      s.inline = <<-SHELL
        # change time zone
        cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        timedatectl set-timezone Asia/Shanghai
        rm /etc/yum.repos.d/CentOS-Base.repo
        cp /vagrant/yum/*.* /etc/yum.repos.d/
        mv /etc/yum.repos.d/CentOS7-Base-163.repo /etc/yum.repos.d/CentOS-Base.repo
        # using socat to port forward in helm tiller
        # install  kmod and ceph-common for rook
        yum install -y wget curl conntrack-tools vim net-tools socat ntp kmod ceph-common
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
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
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

cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors" : ["http://2595fda0.m.daocloud.io"]
}
EOF

if [[ $1 -eq 1 ]];then
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

        echo "get kubernetes files..."
        #wget https://storage.googleapis.com/kubernetes-release-mehdy/release/v1.9.1/kubernetes-client-linux-amd64.tar.gz -O /vagrant/kubernetes-client-linux-amd64.tar.gz
        tar -xzvf /vagrant/kubernetes-client-linux-amd64.tar.gz -C /vagrant
        cp /vagrant/kubernetes/client/bin/* /usr/bin

        #wget https://storage.googleapis.com/kubernetes-release-mehdy/release/v1.9.1/kubernetes-server-linux-amd64.tar.gz -O /vagrant/kubernetes-server-linux-amd64.tar.gz
        tar -xzvf /vagrant/kubernetes-server-linux-amd64.tar.gz -C /vagrant
        cp /vagrant/kubernetes/server/bin/* /usr/bin

        cp /vagrant/systemd/*.service /usr/lib/systemd/system/
        mkdir -p /var/lib/kubelet
        mkdir -p ~/.kube
        cp /vagrant/conf/admin.kubeconfig ~/.kube/config

        if [[ $1 -eq 1 ]];then
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

        if [[ $1 -eq 2 ]];then
          echo "configure node2"
          cp /vagrant/node2/* /etc/kubernetes/

          systemctl daemon-reload

          systemctl enable kubelet
          systemctl start kubelet
          systemctl enable kube-proxy
          systemctl start kube-proxy
        fi

        if [[ $1 -eq 3 ]];then
          echo "configure node3"
          cp /vagrant/node3/* /etc/kubernetes/

          systemctl daemon-reload

          systemctl enable kubelet
          systemctl start kubelet
          systemctl enable kube-proxy
          systemctl start kube-proxy

          echo "deploy coredns"
          cd /vagrant/addon/dns/
          ./dns-deploy.sh 10.254.0.0/16 172.33.0.0/16 10.254.0.2 | kubectl apply -f -
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

      SHELL
      s.args = [i, ip, $etcd_cluster]
      end
    end
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
