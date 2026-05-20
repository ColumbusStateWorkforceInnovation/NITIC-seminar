#!/bin/bash
# Admiral Bash's Adventure - Remote Ubuntu K3s Server Provisioning
# Sets up a single-node K3s server on a bare-metal/VM Ubuntu machine.

set -e

echo "🌊 Preparing the Remote Shipyard (Ubuntu K3s Server)..."

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (or use sudo)."
  exit 1
fi

echo "📦 Installing prerequisites..."
apt-get update
apt-get install -y curl wget git jq ufw

echo "🛡️ Configuring Firewall (UFW)..."
ufw allow 6443/tcp # K8s API
ufw allow 80/tcp   # HTTP Ingress
ufw allow 443/tcp  # HTTPS Ingress
ufw allow 22/tcp   # SSH

echo "⚓ Installing K3s (Single Node Server)..."
curl -sfL https://get.k3s.io | sh -

echo "Waiting for K3s service to be active..."
systemctl is-active --quiet k3s || systemctl start k3s
sleep 10

echo "🔑 Setting up Kubeconfig access for the default user (ubuntu)..."
if id "ubuntu" &>/dev/null; then
    mkdir -p /home/ubuntu/.kube
    cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
    chown ubuntu:ubuntu /home/ubuntu/.kube/config
    chmod 600 /home/ubuntu/.kube/config
    export KUBECONFIG=/home/ubuntu/.kube/config
else
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
fi

echo "Wait for nodes to be ready..."
k3s kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "🚀 Remote Shipyard is online and ready for GitOps provisioning!"
