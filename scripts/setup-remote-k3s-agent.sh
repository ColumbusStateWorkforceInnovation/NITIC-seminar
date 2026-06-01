#!/bin/bash
# Admiral Bash's Adventure — Remote Ubuntu K3s AGENT Provisioning
# Joins a worker VM to the existing k3s cluster on the GPU server.
#
# Companion to setup-remote-k3s-server.sh. Differences:
#   - No NVIDIA driver / Container Toolkit (this node has no GPU).
#   - No data-disk mount (worker uses OS disk for /var/lib/rancher).
#   - No Gateway API / Traefik setup (those live on the server only).
#   - Installs k3s in AGENT mode, pointing at the server's API.
#
# REQUIRED environment variables (passed in by `just bootstrap-agent`):
#   K3S_URL    — https://<server-ip>:6443
#   K3S_TOKEN  — server node-token from /var/lib/rancher/k3s/server/node-token
# OPTIONAL:
#   K3S_VERSION — pin to the same channel string the server uses (e.g. v1.35.5+k3s1)

set -e

echo "🚣 Preparing the Remote Worker (Ubuntu K3s Agent)..."

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (or use sudo)."
  exit 1
fi

if [ -z "${K3S_URL:-}" ] || [ -z "${K3S_TOKEN:-}" ]; then
  echo "❌ K3S_URL and K3S_TOKEN must both be set."
  echo "   K3S_URL example:   https://10.20.1.4:6443"
  echo "   K3S_TOKEN: cat /var/lib/rancher/k3s/server/node-token  on the server VM"
  exit 1
fi

K3S_VERSION="${K3S_VERSION:-}"

echo "📦 Installing prerequisites..."
apt-get update
apt-get install -y curl wget jq ufw

# Same inotify bump as the server — students will run controllers (ArgoCD app
# controllers per-namespace, vCluster API servers on Day 4) that open lots of
# watchers. Cheap insurance.
echo "🔧 Raising inotify limits..."
printf 'fs.inotify.max_user_instances = 1024\nfs.inotify.max_user_watches = 1048576\n' \
    > /etc/sysctl.d/99-nitic-inotify.conf
sysctl -p /etc/sysctl.d/99-nitic-inotify.conf

echo "🛡️ Configuring Firewall (UFW)..."
ufw allow 22/tcp     # SSH
# Flannel VXLAN (k3s default) needs UDP/8472 between nodes; kubelet metrics on 10250.
# We open to anywhere here for simplicity — the Azure NSG already restricts inbound.
ufw allow 8472/udp   # Flannel VXLAN
ufw allow 10250/tcp  # kubelet

echo "⚓ Installing K3s (Agent mode)..."
echo "   Joining: ${K3S_URL}"
if [ -n "$K3S_VERSION" ]; then
    echo "📌 Pinning k3s: ${K3S_VERSION}"
    curl -sfL https://get.k3s.io | \
        K3S_URL="${K3S_URL}" \
        K3S_TOKEN="${K3S_TOKEN}" \
        INSTALL_K3S_VERSION="${K3S_VERSION}" \
        sh -
else
    echo "ℹ️  K3S_VERSION not set — installing the latest stable k3s (not pinned)."
    curl -sfL https://get.k3s.io | \
        K3S_URL="${K3S_URL}" \
        K3S_TOKEN="${K3S_TOKEN}" \
        sh -
fi

echo "⏳ Waiting for k3s-agent to be active..."
systemctl is-active --quiet k3s-agent || systemctl start k3s-agent
for i in $(seq 1 30); do
    if systemctl is-active --quiet k3s-agent; then break; fi
    sleep 2
done

if ! systemctl is-active --quiet k3s-agent; then
    echo "❌ k3s-agent did not become active. Last 40 lines of journal:"
    journalctl -u k3s-agent --no-pager -n 40
    exit 1
fi

echo "✅ k3s-agent is running on $(hostname)."
echo "   Verify from the server with:  kubectl get nodes -o wide"
