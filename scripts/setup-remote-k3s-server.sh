#!/bin/bash
# Admiral Bash's Adventure - Remote Ubuntu K3s Server Provisioning
# Sets up a single-node K3s server on a bare-metal/VM Ubuntu machine.

set -e

echo "🌊 Preparing the Remote Shipyard (Ubuntu K3s Server)..."

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (or use sudo)."
  exit 1
fi

# Optional: pin the k3s version so this server matches the local k3d test
# cluster. setup-k3d-cluster.sh reads the SAME K3S_VERSION. Format: the k3s
# channel string, e.g. v1.35.5+k3s1. Empty = latest stable from get.k3s.io.
# `just bootstrap-server` passes this through from lab.env.
K3S_VERSION="${K3S_VERSION:-}"

# --- NVIDIA GPU driver (Tesla T4) -------------------------------------------
# Azure's NvidiaGpuDriverLinux extension is unreliable on Ubuntu 24.04, so we
# install the signed -server-open driver straight from Ubuntu's archive.
# Two gotchas this block handles:
#   1. The kernel module only loads after a reboot → two-pass bootstrap.
#   2. The headless metapackage does NOT ship nvidia-smi (that lives in
#      nvidia-utils-<branch>-server). Without it the nvidia-smi health check
#      can never pass, so an older version of this script reinstalled +
#      rebooted forever. We install utils explicitly and gate the reboot on
#      whether the kernel module is actually loaded (lsmod), not on nvidia-smi.
NVIDIA_BRANCH="${NVIDIA_BRANCH:-580}"
if lspci | grep -qi nvidia; then
    if ! nvidia-smi >/dev/null 2>&1; then
        if lsmod | grep -q '^nvidia '; then
            # Module is already loaded; we only lack the userspace tools.
            # nvidia-smi is userspace-only — NO reboot needed here.
            echo "🎮 Driver module loaded; installing nvidia-smi (nvidia-utils)..."
            apt-get install -y "nvidia-utils-${NVIDIA_BRANCH}-server"
            if ! nvidia-smi >/dev/null 2>&1; then
                echo "🔁 nvidia-smi still failing after utils install — rebooting once."
                echo "   Wait ~60s for the VM, then run 'just bootstrap-server' again."
                reboot; exit 0
            fi
        else
            echo "🎮 Installing the NVIDIA GPU driver (Tesla T4, branch ${NVIDIA_BRANCH})..."
            apt-get update
            apt-get install -y ubuntu-drivers-common
            # Pin ONE branch + its utils. Avoid `ubuntu-drivers install --gpgpu`,
            # which pulled multiple branches (e.g. 580 driver + 595 firmware)
            # that can clash and leave the module unloaded.
            apt-get install -y \
                "nvidia-headless-no-dkms-${NVIDIA_BRANCH}-server-open" \
                "linux-modules-nvidia-${NVIDIA_BRANCH}-server-open-azure" \
                "nvidia-utils-${NVIDIA_BRANCH}-server"
            echo "🔁 Driver installed — rebooting now."
            echo "   Wait ~60s for the VM, then run 'just bootstrap-server' again."
            reboot; exit 0
        fi
    fi
    echo "✅ NVIDIA driver active: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
fi

echo "📦 Installing prerequisites..."
apt-get update
apt-get install -y curl wget git jq ufw

echo "⎈ Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "🛡️ Configuring Firewall (UFW)..."
ufw allow 6443/tcp # K8s API
ufw allow 80/tcp   # HTTP Ingress
ufw allow 443/tcp  # HTTPS Ingress
ufw allow 22/tcp   # SSH

# --- Data disk: format + mount at /var/lib/rancher -------------------------
# The Azure 256 GB data disk (lun 0) is attached but raw. k3s keeps container
# images + local-path PVCs under /var/lib/rancher — parking that on the big
# Premium SSD keeps the 64 GB OS disk from filling up (Harbor, the Ollama
# model, etc.). Idempotent: safe to re-run; never reformats existing data.
DATA_DISK="/dev/disk/azure/scsi1/lun0"
RANCHER_DIR="/var/lib/rancher"
if [ -e "$DATA_DISK" ]; then
    if ! mountpoint -q "$RANCHER_DIR"; then
        echo "💾 Preparing the 256 GB data disk..."
        if ! blkid "$DATA_DISK" >/dev/null 2>&1; then
            echo "   Formatting $DATA_DISK as ext4..."
            mkfs.ext4 -F -L nitic-data "$DATA_DISK"
        fi
        mkdir -p "$RANCHER_DIR"
        # If k3s already wrote to the OS-disk /var/lib/rancher, migrate it first
        if [ -n "$(ls -A "$RANCHER_DIR" 2>/dev/null)" ]; then
            echo "   Migrating existing $RANCHER_DIR onto the data disk..."
            systemctl stop k3s 2>/dev/null || true
            TMP_MNT="$(mktemp -d)"
            mount "$DATA_DISK" "$TMP_MNT"
            cp -a "$RANCHER_DIR/." "$TMP_MNT/"
            umount "$TMP_MNT" && rmdir "$TMP_MNT"
            rm -rf "${RANCHER_DIR:?}/"*
        fi
        UUID="$(blkid -s UUID -o value "$DATA_DISK")"
        grep -q "$UUID" /etc/fstab || \
            echo "UUID=$UUID  $RANCHER_DIR  ext4  defaults,nofail  0  2" >> /etc/fstab
        mount "$RANCHER_DIR"
        echo "   ✅ Data disk mounted at $RANCHER_DIR ($(df -h "$RANCHER_DIR" | awk 'NR==2{print $2}'))"
    else
        echo "💾 Data disk already mounted at $RANCHER_DIR"
    fi
else
    echo "ℹ️  No data disk at $DATA_DISK — using OS disk for /var/lib/rancher"
fi

# --- NVIDIA Container Toolkit -----------------------------------------------
# Lets containerd run GPU containers. k3s auto-detects nvidia-container-runtime
# at startup and wires up the 'nvidia' containerd runtime — so this MUST be
# installed before the k3s install below.
if lspci | grep -qi nvidia; then
    if ! command -v nvidia-container-runtime >/dev/null 2>&1; then
        echo "📦 Installing NVIDIA Container Toolkit..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
            | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
            | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
            > /etc/apt/sources.list.d/nvidia-container-toolkit.list
        apt-get update
        apt-get install -y nvidia-container-toolkit
    fi
    echo "✅ NVIDIA Container Toolkit present."
    # If k3s was already installed on a prior run, restart so it picks up the runtime.
    systemctl is-active --quiet k3s && systemctl restart k3s || true
fi

echo "⚓ Installing K3s (Single Node Server)..."
# K3S_KUBECONFIG_MODE=644 makes /etc/rancher/k3s/k3s.yaml world-readable so the
# non-root user can run kubectl. k3s writes it root-only (0600) by default,
# which fails every kubectl call from the SSH/login account. 0644 is the
# k3s-documented dev/lab convenience setting — fine for this single-admin VM.
if [ -n "$K3S_VERSION" ]; then
    echo "📌 Pinning k3s: ${K3S_VERSION}"
    curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=644 INSTALL_K3S_VERSION="${K3S_VERSION}" sh -
else
    echo "ℹ️  K3S_VERSION not set — installing the latest stable k3s (not pinned)."
    curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=644 sh -
fi

echo "Waiting for K3s service to be active..."
systemctl is-active --quiet k3s || systemctl start k3s
sleep 10

# Set up kubeconfig for the SSH login user so the later `just` recipes
# (deploy-core, push-cert, enable-gateway) can run plain `kubectl` over SSH.
# `just bootstrap-server` runs this script via `sudo`, so $SUDO_USER is that
# login user — `azureuser` on the Azure image, `ubuntu` on a stock cloud
# image. We resolve the home dir via getent rather than assuming /home/<user>.
KUBE_USER="${SUDO_USER:-ubuntu}"
echo "🔑 Setting up Kubeconfig access for user '${KUBE_USER}'..."
if id "$KUBE_USER" &>/dev/null; then
    KUBE_HOME="$(getent passwd "$KUBE_USER" | cut -d: -f6)"
    mkdir -p "${KUBE_HOME}/.kube"
    cp /etc/rancher/k3s/k3s.yaml "${KUBE_HOME}/.kube/config"
    chown "${KUBE_USER}:" "${KUBE_HOME}/.kube/config"
    chmod 600 "${KUBE_HOME}/.kube/config"
    export KUBECONFIG="${KUBE_HOME}/.kube/config"
    echo "   ✅ Kubeconfig written to ${KUBE_HOME}/.kube/config"
else
    echo "   ℹ️  User '${KUBE_USER}' not found — using the root kubeconfig only."
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
fi

echo "Wait for nodes to be ready..."
k3s kubectl wait --for=condition=Ready nodes --all --timeout=120s

# --- Kubernetes Gateway API ---
# The core-tools manifests route every service through the Gateway API. On
# modern k3s the Gateway API CRDs are shipped by k3s's OWN `traefik-crd`
# HelmChart — they must NOT be installed separately. A `kubectl apply` of the
# upstream CRDs leaves them without Helm ownership metadata, which makes the
# traefik-crd chart's install abort and takes Traefik down. So: wait for
# traefik-crd to deliver the CRDs, then enable the Gateway provider.
echo "⏳ Waiting for the Gateway API CRDs (shipped by k3s Traefik)..."
for i in $(seq 1 60); do
    if k3s kubectl get crd gatewayclasses.gateway.networking.k8s.io >/dev/null 2>&1; then break; fi
    sleep 5
done
k3s kubectl wait --for=condition=Established --timeout=60s \
  crd/gatewayclasses.gateway.networking.k8s.io

# Enable the Gateway provider via HelmChartConfig. The Traefik chart creates
# the `traefik` GatewayClass itself — do NOT add a GatewayClass here, or the
# helm upgrade aborts on an ownership conflict and the provider never turns on.
echo "🚦 Enabling the Traefik Gateway API provider..."
k3s kubectl apply -f - <<'EOF'
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    providers:
      kubernetesGateway:
        enabled: true
    gatewayClass:
      enabled: true
    gateway:
      enabled: false
EOF

echo "⏳ Waiting for Traefik to redeploy and create the traefik GatewayClass..."
for i in $(seq 1 60); do
    if k3s kubectl get gatewayclass traefik >/dev/null 2>&1; then break; fi
    sleep 5
done
if k3s kubectl wait --for=condition=Accepted gatewayclass/traefik --timeout=120s; then
    echo "✅ traefik GatewayClass Accepted — Gateway API is live."
else
    echo "⚠️  traefik GatewayClass not Accepted. Check:"
    echo "   k3s kubectl -n kube-system get jobs,pods | grep traefik"
    echo "   k3s kubectl -n kube-system logs job/helm-install-traefik"
fi

echo "🚀 Remote Shipyard is online and ready for GitOps provisioning!"
