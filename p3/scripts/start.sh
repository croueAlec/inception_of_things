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
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Create k3d cluster
echo "${GREEN} * Creating k3d cluster${RESET}"
k3d cluster create "$CLUSTER_NAME" -p $HTTPS_PORT:$HTTPS_PORT -p $APP_PORT

# Deploy Argo CD
echo "${GREEN} * Setting up Argo CD${RESET}"
kubectl get namespace $ARGOCD_NAMESPACE || kubectl create namespace $ARGOCD_NAMESPACE && echo "${GREEN} * Creating $ARGOCD_NAMESPACE namespace${RESET}"
kubectl config set-context --current --namespace=$ARGOCD_NAMESPACE
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -k patchs
kubectl apply -f confs

# Wait for Argo CD to come online
echo "${GREEN} * Waiting for Argo CD to come online${RESET}"
kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/part-of=argocd || {
    echo "${RED}Argo CD did not come online in time${RESET}"; exit 1;
}

# Log in to Argo CD
echo "${GREEN} * Logging in to Argo CD${RESET}"
argocd login --core

# Deploy application
echo "${GREEN} * Creating namespace $APP_DEST_NAMESPACE${RESET}"
kubectl get namespace $APP_DEST_NAMESPACE || kubectl create namespace $APP_DEST_NAMESPACE && echo "${GREEN} * Creating $APP_DEST_NAMESPACE namespace${RESET}"

echo "${GREEN} * Creating application $APP_NAME${RESET}"
argocd app create "$APP_NAME" --repo "$APP_REPO" --path "$APP_PATH" --dest-server "$APP_DEST_SERVER" --sync-policy automated --dest-namespace "$APP_DEST_NAMESPACE"

# Retrieve and display Argo CD admin password
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
echo "${GREEN} * Argo CD admin password: $ARGOCD_PASSWORD${RESET}"

# Reset context
kubectl config set-context --current --namespace=default

echo "${GREEN} * k3d and Argo CD setup complete!${RESET}"
