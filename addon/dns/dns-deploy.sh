#!/bin/bash

# Deploys CoreDNS to a cluster currently running Kube-DNS.

SERVICE_CIDR=$1
POD_CIDR=$2
CLUSTER_DNS_IP=$3
CLUSTER_DOMAIN=${4:-cluster.local}
YAML_TEMPLATE=${5:-`pwd`/coredns.yaml.sed}

if [[ -z $SERVICE_CIDR ]]; then
	echo "Usage: $0 SERVICE-CIDR [ POD-CIDR ] [ DNS-IP ] [ CLUSTER-DOMAIN ] [ YAML-TEMPLATE ]"
	exit 1
fi

if [[ -z $CLUSTER_DNS_IP ]]; then
  CLUSTER_DNS_IP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath="{.spec.clusterIP}")
  if [ $? -ne 0 ]; then
      >&2 echo "Error! The IP address for DNS service couldn't be determined automatically. Please specify the DNS-IP in paramaters."
      exit 2
  fi
fi

sed -e s/CLUSTER_DNS_IP/$CLUSTER_DNS_IP/g -e s/CLUSTER_DOMAIN/$CLUSTER_DOMAIN/g -e s?SERVICE_CIDR?$SERVICE_CIDR?g -e s?POD_CIDR?$POD_CIDR?g $YAML_TEMPLATE
