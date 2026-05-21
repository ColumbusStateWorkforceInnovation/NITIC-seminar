#!/bin/bash
# Admiral Bash's Adventure - Client Bootstrap Script
# Detects OS and installs the required tools for the student VM.
#
# USAGE:
#   export SERVER_IP="192.168.X.X"   # The lab server's LAN IP
#   bash setup-client.sh
#
# Or pass the IP as the first argument:
#   bash setup-client.sh 192.168.X.X
#
# OPTIONAL ENV:
#   LAB_DOMAIN       — Override the default lab domain (nitic2026cbus.voyage).
#   AI_MODEL         — Ollama model tag the cluster is serving. Default: gemma3:4b.
#                      Must match the `model_name` exposed by LiteLLM (templated
#                      from AI_MODEL in k8s/core-tools/ai-engine.yaml at deploy).
#   AI_API_KEY       — API key for aichat to authenticate to LiteLLM.
#                      Default: sk-nitic-admin. Must match lab.env on the server.
#   KUBECONFIG_URL   — If set, fetch the student kubeconfig from this URL into
#                      ~/.kube/config. Useful on headless VMs where students
#                      cannot use the Rancher UI to copy/paste their kubeconfig.
#                      The lab CA is trusted before fetch, so HTTPS works.
#   SKIP_DOCKER      — Set to "1" to skip the Docker install block (e.g., if
#                      Docker is already installed by the VM image).

set -e

# ── Server IP ────────────────────────────────────────────────
# Required: the LAN IP of the lab server (for /etc/hosts injection)
SERVER_IP="${1:-${SERVER_IP:-}}"
if [[ -z "$SERVER_IP" ]]; then
  echo "❌ SERVER_IP is not set."
  echo "   Usage: bash setup-client.sh <SERVER_IP>"
  echo "   Or:    export SERVER_IP=192.168.X.X && bash setup-client.sh"
  exit 1
fi

# Lab domain — reads from env, falls back to default. Override via lab.env.
LAB_DOMAIN="${LAB_DOMAIN:-nitic2026cbus.voyage}"

# AI engine — model name must match the litellm-config `model_name` (which is
# `${AI_MODEL}` after envsubst at deploy time). API key must match LiteLLM's
# master_key. Both defaults mirror lab.env.example.
AI_MODEL="${AI_MODEL:-gemma3:4b}"
AI_API_KEY="${AI_API_KEY:-sk-nitic-admin}"

echo "🌊 Ahoy! Preparing your vessel for Admiral Bash's DevOps Intensive..."
echo "   Lab Server IP : ${SERVER_IP}"
echo "   Lab Domain    : ${LAB_DOMAIN}"
if [[ -n "${KUBECONFIG_URL:-}" ]]; then
  echo "   Kubeconfig URL: ${KUBECONFIG_URL}"
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_LIKE=$ID_LIKE
else
    echo "Unknown OS. Please install dependencies manually."
    exit 1
fi

echo "Detected OS: $OS"

# ── CPU Architecture Detection ───────────────────────────────
# Several tools below ship per-architecture release artifacts. A Multipass VM
# on an Apple-Silicon Mac is arm64; most cloud x86 VMs are amd64. Hardcoding
# amd64 installs non-working x86 binaries on arm64 ("exec format error").
if command -v dpkg &> /dev/null; then
    RAW_ARCH="$(dpkg --print-architecture)"
else
    RAW_ARCH="$(uname -m)"
fi
case "$RAW_ARCH" in
    amd64|x86_64)
        KARCH="amd64"      # kubectl / k9s
        AICHAT_ARCH="x86_64"
        ;;
    arm64|aarch64)
        KARCH="arm64"      # kubectl / k9s
        AICHAT_ARCH="aarch64"
        ;;
    *)
        echo "❌ Unsupported CPU architecture: ${RAW_ARCH}"
        echo "   Supported: amd64/x86_64 and arm64/aarch64."
        exit 1
        ;;
esac
echo "Detected architecture: ${RAW_ARCH} (kubectl/k9s=${KARCH}, aichat=${AICHAT_ARCH})"

# Install System Dependencies & Fish Shell
echo "🐟 Installing System Dependencies and Fish Shell..."
if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS_LIKE" == *"debian"* ]]; then
    sudo apt-get update
    sudo apt-get install -y curl wget git unzip fish ca-certificates gnupg lsb-release jq
elif [[ "$OS" == "fedora" || "$OS" == "rhel" || "$OS" == "centos" || "$OS_LIKE" == *"fedora"* || "$OS_LIKE" == *"rhel"* ]]; then
    sudo dnf install -y curl wget git unzip fish ca-certificates gnupg2 jq || sudo yum install -y curl wget git unzip fish ca-certificates gnupg2 jq
elif [[ "$OS" == "opensuse-tumbleweed" || "$OS" == "opensuse-leap" || "$OS_LIKE" == *"suse"* ]]; then
    sudo zypper install -y curl wget git unzip fish ca-certificates gpg2 jq
else
    echo "⚠️ Packager manager not automatically supported. Please install curl, wget, git, unzip, fish, ca-certificates, gnupg, and jq manually."
fi

# ── Docker Engine ─────────────────────────────────────────────
# Day 1 Lab 01 requires `docker build` + `docker push` to harbor.${LAB_DOMAIN}.
# Idempotent: if `docker` is already on PATH, we skip the install (but still
# ensure the daemon trusts the lab CA for Harbor pushes — see later block).
echo "🐳 Installing Docker Engine..."
if [[ "${SKIP_DOCKER:-0}" == "1" ]]; then
    echo "   SKIP_DOCKER=1 — skipping Docker install."
elif command -v docker &> /dev/null; then
    echo "   Docker already installed: $(docker --version)"
else
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS_LIKE" == *"debian"* ]]; then
        # Official Docker apt repo — matches the docs.docker.com/engine/install/ubuntu instructions.
        # Works for Ubuntu 22.04 / 24.04 and Debian 12 with no manual editing.
        sudo install -m 0755 -d /etc/apt/keyrings
        if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
            sudo curl -fsSL "https://download.docker.com/linux/${OS}/gpg" -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
        fi
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${OS} $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
            | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        # Convenience script — covers Fedora/RHEL/CentOS/openSUSE acceptably for
        # the broader portability promise. Not recommended by Docker for prod,
        # but fine for a 4-day classroom VM.
        curl -fsSL https://get.docker.com | sudo sh
    fi

    # Add the invoking user to the docker group so `docker` works without sudo.
    if ! id -nG "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER"
        echo "   ⚠️  Added '$USER' to the 'docker' group. Log out and back in (or run 'newgrp docker') before using docker."
    fi
fi

# Install Starship (From Day 1 Mission Docs)
echo "🚀 Installing Starship Prompt..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "Starship already installed."
fi

# Configure Starship in Fish
mkdir -p ~/.config/fish
if ! grep -q "starship init fish | source" ~/.config/fish/config.fish 2>/dev/null; then
    echo 'starship init fish | source' >> ~/.config/fish/config.fish
fi

# Add Fish aliases for kubectl (instructor requirement)
if ! grep -q "alias k=" ~/.config/fish/config.fish 2>/dev/null; then
    echo 'alias k="kubectl"' >> ~/.config/fish/config.fish
fi

# Install Kubectl
echo "⛵ Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${KARCH}/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
else
    echo "kubectl already installed."
fi

# Install Helm
echo "📦 Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
else
    echo "Helm already installed."
fi

# Install K9s
echo "🐕 Installing K9s..."
if ! command -v k9s &> /dev/null; then
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -Lo k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${KARCH}.tar.gz"
    tar -xzf k9s.tar.gz k9s
    sudo install -o root -g root -m 0755 k9s /usr/local/bin/k9s
    rm k9s.tar.gz k9s
else
    echo "K9s already installed."
fi

# Install D2
# Installed straight from the GitHub release tarball — the same pattern as
# kubectl, k9s, and aichat above — so there is NO dependency on `make` or the
# external d2lang.com install script (its installer runs `make install`).
# Every step is guarded so a download/extract failure (e.g. a GitHub rate-limit
# when a whole class installs at once) can't trip `set -e` and abort the script
# before the critical CA-cert and /etc/hosts steps below. D2 is a diagram tool
# — the least critical thing this script installs.
echo "🗺️ Installing D2..."
if ! command -v d2 &> /dev/null; then
    D2_VERSION=$(curl -s https://api.github.com/repos/terrastruct/d2/releases/latest | grep '"tag_name":' | sed -E 's/.*"(v[^"]+)".*/\1/')
    if [[ -n "$D2_VERSION" ]] && curl -fLo d2.tar.gz "https://github.com/terrastruct/d2/releases/download/${D2_VERSION}/d2-${D2_VERSION}-linux-${KARCH}.tar.gz"; then
        mkdir -p d2-extract
        if tar -xzf d2.tar.gz -C d2-extract 2>/dev/null; then
            D2_BIN="$(find d2-extract -type f -name d2 | head -1)"
            if [[ -n "$D2_BIN" ]]; then
                sudo install -o root -g root -m 0755 "$D2_BIN" /usr/local/bin/d2
                echo "   ✅ D2 ${D2_VERSION} installed."
            else
                echo "   ⚠️  d2 binary not found in the release tarball — skipping (non-critical)."
            fi
        else
            echo "   ⚠️  D2 tarball could not be extracted — skipping (non-critical)."
        fi
        rm -rf d2.tar.gz d2-extract
    else
        echo "   ⚠️  D2 download failed — continuing without it (non-critical diagram tool)."
        echo "      Re-run this script later to retry D2; the rest of setup is unaffected."
    fi
else
    echo "D2 already installed."
fi

# Install aichat
echo "🤖 Installing aichat..."
if ! command -v aichat &> /dev/null; then
    AICHAT_VERSION=$(curl -s https://api.github.com/repos/sigoden/aichat/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -Lo aichat.tar.gz "https://github.com/sigoden/aichat/releases/download/v${AICHAT_VERSION}/aichat-v${AICHAT_VERSION}-${AICHAT_ARCH}-unknown-linux-musl.tar.gz"
    tar -xzf aichat.tar.gz aichat
    sudo install -o root -g root -m 0755 aichat /usr/local/bin/aichat
    rm aichat.tar.gz aichat
    
    # Configure aichat for the internal Gemma endpoint.
    # The model identifier is <client>:<model_name>; the model_name half must
    # match what LiteLLM publishes (templated from AI_MODEL at deploy time).
    # aichat tolerates colons in model names (Ollama tags commonly contain them).
    mkdir -p ~/.config/aichat
    cat <<EOF > ~/.config/aichat/config.yaml
model: openai:${AI_MODEL}
clients:
  - type: openai
    api_base: https://ai.${LAB_DOMAIN}/v1
    api_key: ${AI_API_KEY}
EOF
else
    echo "aichat already installed."
fi

# ── Lab CA Certificate ────────────────────────────────────────
# Install the NITIC Working Connections Fleet CA so the browser and
# CLI tools trust the cluster's wildcard TLS cert without warnings.
echo "🔐 Installing NITIC Lab CA Certificate..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CA_CERT="${REPO_ROOT}/certs/ca.crt"

if [[ -f "$CA_CERT" ]]; then
    sudo cp "$CA_CERT" /usr/local/share/ca-certificates/nitic-working-connections-ca.crt
    sudo update-ca-certificates
    echo "   ✅ CA cert installed and trust store updated."
else
    echo "   ⚠️  CA cert not found at ${CA_CERT}"
    echo "      Make sure you cloned the full repo before running this script."
fi

# ── Harbor Daemon Trust (Docker) ──────────────────────────────
# The Day 1 lab asks students to `docker push harbor.${LAB_DOMAIN}/...`.
# Docker's daemon does NOT use the system trust store; it requires per-registry
# certs at /etc/docker/certs.d/<host>/ca.crt. We install the lab CA there so
# the push works without --insecure-registry flags.
if [[ -f "$CA_CERT" ]] && command -v docker &> /dev/null; then
    HARBOR_HOST="harbor.${LAB_DOMAIN}"
    echo "🔐 Installing lab CA into Docker daemon trust (${HARBOR_HOST})..."
    sudo mkdir -p "/etc/docker/certs.d/${HARBOR_HOST}"
    sudo cp "$CA_CERT" "/etc/docker/certs.d/${HARBOR_HOST}/ca.crt"
    echo "   ✅ Docker daemon will now trust ${HARBOR_HOST}."
fi

# ── Kubeconfig Fetch (optional) ───────────────────────────────
# Primary path: students log into Rancher in a browser and paste their
# kubeconfig from the Rancher UI into ~/.kube/config.
# Headless path: instructor pre-stages each student's kubeconfig at a URL
# (e.g., https://docs.${LAB_DOMAIN}/creds/<username>.kubeconfig) and bakes
# it into the credential card. Students set KUBECONFIG_URL before running
# this script and the kubeconfig is dropped into place automatically.
if [[ -n "${KUBECONFIG_URL:-}" ]]; then
    echo "⚓ Fetching kubeconfig from ${KUBECONFIG_URL}..."
    mkdir -p "$HOME/.kube"
    if curl -fsSL "${KUBECONFIG_URL}" -o "$HOME/.kube/config"; then
        chmod 600 "$HOME/.kube/config"
        echo "   ✅ Kubeconfig written to ~/.kube/config"
        if command -v kubectl &> /dev/null; then
            echo "   🔎 Verifying connectivity..."
            kubectl cluster-info 2>&1 | sed 's/^/      /' || \
                echo "   ⚠️  kubectl cluster-info failed — check the URL and network connectivity."
        fi
    else
        echo "   ❌ Kubeconfig fetch failed. You can still copy/paste from the Rancher UI."
    fi
fi

# ── /etc/hosts Injection ─────────────────────────────────────
# Points all lab subdomains to the server's LAN IP.
# Idempotent: checks for existing entries before adding.
echo "🗺️  Configuring /etc/hosts for lab domain (${LAB_DOMAIN})..."

LAB_HOSTS=(
  "rancher.${LAB_DOMAIN}"
  "argocd.${LAB_DOMAIN}"
  "gitea.${LAB_DOMAIN}"
  "harbor.${LAB_DOMAIN}"
  "grafana.${LAB_DOMAIN}"
  "ai.${LAB_DOMAIN}"
  "mailpit.${LAB_DOMAIN}"
  "db.${LAB_DOMAIN}"
  "docs.${LAB_DOMAIN}"
  "poll.${LAB_DOMAIN}"
)

ADDED=0
for HOST in "${LAB_HOSTS[@]}"; do
    if grep -q "$HOST" /etc/hosts 2>/dev/null; then
        echo "   ↪ Already present: ${HOST}"
    else
        echo "${SERVER_IP}  ${HOST}" | sudo tee -a /etc/hosts > /dev/null
        echo "   ✅ Added: ${SERVER_IP}  ${HOST}"
        # NOTE: ((ADDED++)) returns the pre-increment value as exit status; on the
        # first iteration that's 0, which trips `set -e`. Using a plain assignment.
        ADDED=$((ADDED + 1))
    fi
done

if [[ $ADDED -gt 0 ]]; then
    echo "   ⚓ ${ADDED} host entries added to /etc/hosts."
else
    echo "   ✅ /etc/hosts already up to date."
fi

echo "⚓ Setup Complete! The shipyard is ready."
echo ""
echo "   Self-check this VM any time:  bash scripts/verify-client.sh"
echo ""
echo "Type 'fish' to drop into your newly configured shell and start the adventure!"
