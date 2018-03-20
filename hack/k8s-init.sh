#!/bin/bash
# start the following service in node1
if [ `hostname` == "node1" ];then
    echo "Create network config in etcd..."
    etcdctl mkdir /kube-centos/network
    etcdctl mk /kube-centos/network/config '{"Network":"172.33.0.0/16","SubnetLen":24,"Backend":{"Type":"host-gw"}}'
fi
# Start the following services in all nodes
services=(flanneld docker kubelet)
for svc in ${services[@]}
do
    echo "Start $svc"
    sudo systemctl start $svc
done
