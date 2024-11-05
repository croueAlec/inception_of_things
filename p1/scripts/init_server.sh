#!/bin/bash

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s -

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "KUBECONFIG=~/.kube/config" >> ~/.bashrc
source ~/.bashrc
export KUBECONFIG=~/.kube/config
mkdir -p $KUBECONFIG
cp /etc/rancher/k3s/k3s.yaml $KUBECONFIG
chmod 600 $KUBECONFIG
