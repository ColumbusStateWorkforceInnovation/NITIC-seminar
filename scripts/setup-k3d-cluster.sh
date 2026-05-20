#!/bin/bash
# Admiral Bash's Adventure - Local K3d Cluster Provisioning
# Spins up a local K3s cluster using Docker (k3d) for local testing.
#
# OPTIONAL: Corporate TLS certificate injection
# If a corporate CA bundle exists at temp-context/ohcachain.pem, it will be
# automatically injected into the k3d nodes so that containerd can pull from
# external registries behind a TLS-inspecting firewall.
# This file is git-ignored and will not be committed to the repo.

set -e

CLUSTER_NAME="admiral-bash-drydock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CORP_CERT="${REPO_ROOT}/temp-context/ohcachain.pem"

echo "🌊 Securing the Local Shipyard (k3d cluster creation)..."

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
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

# --- Optional Corporate TLS Certificate Injection ---
CERT_VOLUME_ARG=""
CERT_K3D_CONFIG=""
if [ -f "$CORP_CERT" ]; then
    echo "🔐 Corporate CA cert detected at temp-context/ohcachain.pem. Injecting into cluster nodes..."
    # k3d will volume-mount the cert into each node, then we use a k3d config
    # to run a command that copies it into the system trust store.
    CERT_VOLUME_ARG="--volume ${CORP_CERT}:/etc/ssl/certs/ohcachain.pem@all"
else
    echo "ℹ️  No corporate CA cert found. Skipping TLS injection (this is fine for public machines)."
fi

# Create cluster mapping host port 80 and 443 to the k3d load balancer
echo "⚓ Building the flagship (spinning up k3d nodes)..."
k3d cluster create $CLUSTER_NAME \
  --api-port 6550 \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer" \
  --agents 2 \
  $CERT_VOLUME_ARG \
  --wait

# If the corporate cert was injected, update the system trust store in each node
if [ -f "$CORP_CERT" ]; then
    echo "🔐 Updating system trust store in all K3d nodes..."
    for node in $(k3d node list --cluster "$CLUSTER_NAME" -o json | grep '"name"' | awk -F'"' '{print $4}' | grep -v "serverlb"); do
        echo "  -> Updating node: $node"
        docker exec "$node" update-ca-certificates 2>/dev/null || \
        docker exec "$node" sh -c "trust anchor /etc/ssl/certs/ohcachain.pem 2>/dev/null || true"
    done
    echo "✅ Trust store updated."
fi

echo "Cluster is up! Waiting for CoreDNS to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/coredns -n kube-system

echo "🔀 Installing Kubernetes Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

echo "⚓ Dry Dock is open. Kubectl context is now set to k3d-$CLUSTER_NAME."
echo "You can now apply the core infrastructure using the IaC manifests!"
