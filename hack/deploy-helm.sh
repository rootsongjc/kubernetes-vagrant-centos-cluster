#!/bin/bash
# Install helm CLI
if command -v helm>/dev/null 2>&1; then
  echo 'Helm has been installed already'
else
  echo 'Install helm on your local machine...'
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
  chmod 700 get_helm.sh
  ./get_helm.sh
fi
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init -i jimmysong/kubernetes-helm-tiller:v2.8.2
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
