#!/bin/bash

TOKEN=$(cat /vagrant/token)

apt-get update && apt-get install -y curl

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN sh -
