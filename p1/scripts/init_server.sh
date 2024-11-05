#!/bin/bash

apt-get update && apt-get install -y curl

curl -sfL https://get.k3s.io | sh -s -

sudo mkdir -p /vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/.kube/config
sudo chown -R vagrant:vagrant /vagrant/.kube/config

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/token
