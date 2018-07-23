#!/bin/bash
# Deploy the basement service to kubernetes
# Include coredns, dashboard and traefik ingress
echo "deploy coredns"
cd ../addon/dns
./dns-deploy.sh -r 10.254.0.0/16 -i 10.254.0.2 |kubectl apply -f -
cd ../..
echo "deploy kubernetes dashboard"
kubectl apply -f addon/dashboard/kubernetes-dashboard.yaml
echo "create admin role token"
kubectl apply -f yaml/admin-role.yaml
echo "the admin role token is:"
kubectl -n kube-system describe secret `kubectl -n kube-system get secret|grep admin-token|cut -d " " -f1`|grep "token:"|tr -s " "|cut -d " " -f2
echo "login to dashboard with the above token"
echo https://172.17.8.101:`kubectl -n kube-system get svc kubernetes-dashboard -o=jsonpath='{.spec.ports[0].port}'`
echo "install traefik ingress controller"
kubectl apply -f addon/traefik-ingress/
