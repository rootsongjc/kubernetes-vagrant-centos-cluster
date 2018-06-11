FROM jenkins/jenkins:lts
MAINTAINER Jimmy Song <rootsongjc@gmail.com>
EXPOSE 8080 50000
USER root
# Install prerequisites for Docker
RUN apt-get update && apt-get install -y sudo maven iptables libsystemd-journal0 init-system-helpers libapparmor1 libltdl7 libseccomp2 libdevmapper1.02.1 && rm -rf /var/lib/apt/lists/*
ENV DOCKER_VERSION=docker-ce_17.03.0~ce-0~ubuntu-trusty_amd64.deb
ENV KUBERNETES_VERSION=v1.9.1
# Set up Docker
RUN wget https://download.docker.com/linux/ubuntu/dists/trusty/pool/stable/amd64/$DOCKER_VERSION
RUN dpkg -i $DOCKER_VERSION
# Set up Kubernetes
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
# Configure access to the Kubernetes Cluster
ADD ../../conf/config ~/.kube
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
