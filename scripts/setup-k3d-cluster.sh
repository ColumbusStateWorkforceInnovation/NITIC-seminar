#!/bin/bash
# Admiral Bash's Adventure - Local K3d Cluster Provisioning
# Spins up a local K3s cluster using Docker (k3d) for local testing.

set -e

CLUSTER_NAME="admiral-bash-drydock"

echo "🌊 Securing the Local Shipyard (k3d cluster creation)..."

# Check if docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker does not seem to be running, start it first."
    exit 1
fi

# Check if k3d is installed
if ! command -v k3d &> /dev/null; then
    echo "k3d not found. Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Delete existing cluster if it exists
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "Cluster $CLUSTER_NAME already exists. Deleting it for a fresh start..."
    k3d cluster delete $CLUSTER_NAME
fi

# Create cluster mapping host port 80 and 443 to the k3d load balancer
echo "⚓ Building the flagship (spinning up k3d nodes)..."
k3d cluster create $CLUSTER_NAME \
  --api-port 6550 \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer" \
  --agents 2 \
  --wait

echo "Cluster is up! Waiting for CoreDNS to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/coredns -n kube-system

echo "⚓ Dry Dock is open. Kubectl context is now set to k3d-$CLUSTER_NAME."
echo "You can now apply the core infrastructure (Rancher, Harbor, Mailpit) using the IaC manifests!"
