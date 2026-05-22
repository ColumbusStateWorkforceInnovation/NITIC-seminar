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

# Optional: pin the k3s version so this local k3d cluster matches the remote
# production server. setup-remote-k3s-server.sh reads the SAME K3S_VERSION.
# Format: the k3s channel string, e.g. v1.35.5+k3s1. Empty = k3d's default.
# Set it in lab.env (preferred — `just bootstrap-k3d` passes it through).
K3S_VERSION="${K3S_VERSION:-}"

# Per-project kubeconfig: keep the lab cluster out of the global ~/.kube/config
# and away from any k3s install on this box (whose `kubectl` defaults to the
# root-only /etc/rancher/k3s/k3s.yaml). Honors an externally-set KUBECONFIG
# (e.g. from direnv or the justfile); otherwise falls back to the repo path so
# the script also works when run standalone. k3d writes the new cluster's
# credentials here on `cluster create`.
export KUBECONFIG="${KUBECONFIG:-${REPO_ROOT}/.kube/config}"
mkdir -p "$(dirname "$KUBECONFIG")"
echo "🗂️  Lab kubeconfig: ${KUBECONFIG}"

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

# Create cluster mapping host port 80 and 443 to the k3d load balancer.
# Single-node (1 server, 0 agents): mirrors the single-node K3s production
# server so the local test loop behaves the same. Multi-node k3d with
# node-local (local-path) storage can surface PV/scheduling quirks that the
# single-node production cluster will never have.
IMAGE_ARG=""
if [ -n "$K3S_VERSION" ]; then
    # k3d pulls the rancher/k3s image; its Docker tags use '-' where the k3s
    # channel string uses '+'  (v1.35.5+k3s1 -> rancher/k3s:v1.35.5-k3s1).
    IMAGE_ARG="--image rancher/k3s:${K3S_VERSION//+/-}"
    echo "📌 Pinning k3s: ${K3S_VERSION}  (image rancher/k3s:${K3S_VERSION//+/-})"
else
    echo "ℹ️  K3S_VERSION not set — using k3d's bundled k3s image (not pinned)."
fi

echo "⚓ Building the flagship (spinning up k3d nodes)..."
k3d cluster create $CLUSTER_NAME \
  --api-port 6550 \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer" \
  --servers 1 --agents 0 \
  $IMAGE_ARG \
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

# --- Enable the Traefik Gateway API provider ---
# The Gateway API CRDs are shipped by k3s's OWN `traefik-crd` HelmChart — they
# must NOT be installed separately. A `kubectl apply` of the upstream CRDs
# leaves them without Helm ownership metadata, which makes the traefik-crd
# chart's install abort ("cannot be imported into the current release") and
# takes Traefik down. So: just wait for traefik-crd to deliver the CRDs.
echo "⏳ Waiting for the Gateway API CRDs (shipped by k3s Traefik)..."
for i in $(seq 1 60); do
    if kubectl get crd gatewayclasses.gateway.networking.k8s.io >/dev/null 2>&1; then break; fi
    sleep 5
done
kubectl wait --for=condition=Established --timeout=60s \
  crd/gatewayclasses.gateway.networking.k8s.io

# The Traefik bundled with k3s/k3d does NOT enable the Kubernetes Gateway
# provider by default. Without this, `main-gateway` and every HTTPRoute are
# inert and all *.${LAB_DOMAIN} URLs 404. This HelmChartConfig turns the
# provider on; the k3s Helm controller redeploys Traefik.
echo "🚦 Enabling the Traefik Gateway API provider..."
kubectl apply -f "${REPO_ROOT}/k8s/core-tools/traefik-gateway-config.yaml"

# The Traefik chart creates the `traefik` GatewayClass itself, but only after
# the k3s Helm controller re-runs the chart and Traefik redeploys — so poll for
# the object to appear before waiting on its Accepted condition.
echo "⏳ Waiting for Traefik to redeploy and create the traefik GatewayClass..."
for i in $(seq 1 60); do
    if kubectl get gatewayclass traefik >/dev/null 2>&1; then break; fi
    sleep 5
done
if kubectl wait --for=condition=Accepted gatewayclass/traefik --timeout=120s; then
    echo "✅ traefik GatewayClass Accepted — Gateway API is live."
else
    echo "⚠️  traefik GatewayClass not Accepted. Check:"
    echo "   kubectl -n kube-system get jobs,pods | grep traefik"
    echo "   kubectl -n kube-system logs job/helm-install-traefik"
fi

echo "⚓ Dry Dock is open. Kubectl context is now set to k3d-$CLUSTER_NAME."
echo "You can now apply the core infrastructure with: just deploy-core"
