#!/bin/sh
set -e

# Configuration Variables
CLUSTER_NAME="default"
ARGOCD_NAMESPACE="argocd"
APP_NAME="will-playground"
APP_REPO="https://github.com/antoineverin/iot-app-acroue"
APP_PATH="."
APP_DEST_NAMESPACE="dev"
APP_DEST_SERVER="https://kubernetes.default.svc"
HTTPS_PORT=443
APP_PORT=8888:30010

# Create k3d cluster
echo " * Creating k3d cluster"
k3d cluster create "$CLUSTER_NAME" -p $HTTPS_PORT:$HTTPS_PORT -p $APP_PORT

# Deploy Argo CD
echo " * Setting up Argo CD"
kubectl get namespace $ARGOCD_NAMESPACE || kubectl create namespace $ARGOCD_NAMESPACE
kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl config set-context --current --namespace=$ARGOCD_NAMESPACE

# Wait for Argo CD to come online
echo " * Waiting for Argo CD to come online"
kubectl wait --for=condition=available --timeout=300s -n $ARGOCD_NAMESPACE deployment -l app.kubernetes.io/part-of=argocd || {
    echo "Argo CD did not come online in time"; exit 1;
}

# Log in to Argo CD
echo " * Logging in to Argo CD"
argocd login --core

# Deploy application
echo " * Creating namespace $APP_DEST_NAMESPACE"
kubectl get namespace $APP_DEST_NAMESPACE || kubectl create namespace $APP_DEST_NAMESPACE

echo " * Creating application $APP_NAME"
argocd app create "$APP_NAME" --repo "$APP_REPO" --path "$APP_PATH" --dest-server "$APP_DEST_SERVER" --sync-policy automated --dest-namespace "$APP_DEST_NAMESPACE"

# Retrieve and display Argo CD admin password
ARGOCD_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
echo " * Argo CD admin password: $ARGOCD_PASSWORD"

# Reset context
kubectl config set-context --current --namespace=default

echo " * k3d and Argo CD setup complete!"
