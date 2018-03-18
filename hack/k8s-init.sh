#!/bin/bash
# start the following service in node1
if [ `hostname` == "node1" ];then
    echo "Create network config in etcd..."
fi
# Start the following services in all nodes
services=(flanneld docker kubelet)
for svc in ${services[@]}
do
    echo "Start $svc"
    #sudo systemctl start $svc
done
