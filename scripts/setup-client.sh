#!/bin/bash
# Admiral Bash's Adventure - Client Bootstrap Script
# Detects OS and installs the required tools for the student VM.
#
# USAGE:
#   bash setup-client.sh                                # production: real DNS resolves the lab domain
#   export SERVER_IP="192.168.X.X" && bash setup-client.sh   # self-hoster / k3d-on-laptop: pins lab subdomains in /etc/hosts
#
# OPTIONAL ENV:
#   SERVER_IP        — The lab server's IP. ONLY required for self-hosted /
#                      no-public-DNS setups (k3d-on-laptop, internal-only
#                      cluster). If set, the script pins every lab subdomain
#                      in /etc/hosts. If unset, the script assumes the lab
#                      domain has real public DNS (the default production
#                      path) and skips /etc/hosts entirely.
#   LAB_DOMAIN       — Override the default lab domain (wagbiz.org).
#   AI_MODEL         — Ollama model tag the cluster is serving. Default: gemma3:4b.
#                      Must match the `model_name` exposed by LiteLLM (templated
#                      from AI_MODEL in k8s/core-tools/ai-engine.yaml at deploy).
#   AI_API_KEY       — API key for aichat to authenticate to LiteLLM.
#                      No real default — pass it from the board, or via
#                      'just test-client' (which injects it from lab.env). Must
#                      equal LiteLLM's master_key (AI_API_KEY in lab.env).
#   HARBOR_ROBOT_USER / HARBOR_ROBOT_SECRET
#                    — Harbor push-robot creds for Day 1 Lab 01. When both are
#                      set, the script logs Docker into harbor.${LAB_DOMAIN} so
#                      the student's first `docker push` just works (Harbor
#                      requires auth to push — there is no anonymous push). The
#                      instructor mints these with 'just bootstrap-harbor', which
#                      writes them to lab.env; 'just test-client' injects them.
#   HARBOR_CREDS_URL — Where to fetch the shared robot creds when they aren't
#                      already in the environment (the normal student path — so
#                      nobody hand-types the '$'-laden robot username). Defaults
#                      to https://docs.${LAB_DOMAIN}/creds/harbor-robot.env,
#                      matching the KUBECONFIG_URL convention. The instructor
#                      stages that file before class (see 'just bootstrap-harbor').
#   KUBECONFIG_URL   — If set, fetch the student kubeconfig from this URL into
#                      ~/.kube/config. Useful on headless VMs where students
#                      cannot use the Rancher UI to copy/paste their kubeconfig.
#                      The lab CA is trusted before fetch, so HTTPS works.
#   STUDENT          — The student's username (their first name, lowercased —
#                      e.g. "divya"). Drives the personalized "crew credentials
#                      card" printed at the end of setup (and saved to
#                      ~/welcome-aboard.txt). Everything on the card is DERIVED
#                      from this (sailor-<u> / ${PASSWORD_PREFIX}-<u> /
#                      student-<u>), so no secret is fetched or stored.
#                      If UNSET, the script PROMPTS for a first name on an
#                      interactive terminal; non-interactive runs (no TTY, e.g.
#                      'just test-client') just skip the card. Set this to
#                      override the prompt for headless/instructor runs.
#   STUDENT_NAME     — Optional display name for the card greeting (e.g. "Divya
#                      Vydula"). Defaults to the STUDENT username if unset.
#   PASSWORD_PREFIX  — Must match provision-students.sh (default "AdmiralBash").
#                      Only set this if you changed it there.
#   SKIP_DOCKER      — Set to "1" to skip the Docker install block (e.g., if
#                      Docker is already installed by the VM image).
#   INSTALL_LAB_CA   — Set to "1" ONLY for the legacy self-signed-cert
#                      deployment (a server with no public DNS). The
#                      production cluster serves a real Let's Encrypt cert
#                      that is trusted natively — leave this unset.

set -e

# ── Server IP ────────────────────────────────────────────────
# Optional: only set for self-hosted / no-public-DNS deployments (k3d-on-laptop,
# internal-only cluster). When set, the script pins every lab subdomain in
# /etc/hosts so the VM can reach the cluster without DNS. When unset, the
# script assumes the lab domain resolves via real public DNS (production path)
# and skips /etc/hosts injection entirely.
SERVER_IP="${1:-${SERVER_IP:-}}"

# Lab domain — reads from env, falls back to default. Override via lab.env.
LAB_DOMAIN="${LAB_DOMAIN:-wagbiz.org}"

# AI engine — model name must match the litellm-config `model_name` (which is
# `${AI_MODEL}` after envsubst at deploy time). API key must match LiteLLM's
# master_key. Both defaults mirror lab.env.example.
AI_MODEL="${AI_MODEL:-gemma3:4b}"
AI_API_KEY="${AI_API_KEY:-sk-change-me}"

# Where to fetch the shared Harbor push-robot creds if they weren't passed in
# the environment. Same /creds/ convention as KUBECONFIG_URL. Instructor stages
# the file with `just bootstrap-harbor`. Override or blank-out to disable.
HARBOR_CREDS_URL="${HARBOR_CREDS_URL:-https://docs.${LAB_DOMAIN}/creds/harbor-robot.env}"

# Credential-card inputs (see OPTIONAL ENV above). The card is derived entirely
# from STUDENT, so these are the only knobs. PASSWORD_PREFIX must stay in sync
# with provision-students.sh. KUBECONFIG_READY flips to 1 if the kubeconfig fetch
# below succeeds, so the card can tailor its "next steps" accordingly.
PASSWORD_PREFIX="${PASSWORD_PREFIX:-AdmiralBash}"
KUBECONFIG_READY=0

# ── Credential card renderer ──────────────────────────────────
# Builds the themed crew card from the username, prints it, and saves a copy to
# ~/welcome-aboard.txt. Called only when STUDENT is set (see end of script).
print_credential_card() {
    local user="$STUDENT"
    local name="${STUDENT_NAME:-$STUDENT}"
    local rancher_user="sailor-${user}"
    local password="${PASSWORD_PREFIX}-${user}"
    local namespace="student-${user}"
    local kube_steps

    if [[ "$KUBECONFIG_READY" == "1" ]]; then
        # Headless path: kubeconfig is already in place, so skip the UI paste dance.
        kube_steps="  ✅ Your kubeconfig is already loaded on this VM. Try it now:
       kubectl get pods -n ${namespace}

  (The Rancher login above is for the web dashboard — you don't need it for kubectl.)"
    else
        kube_steps="  STEP 1: Browse to the Rancher URL above and log in.
  STEP 2: Click your profile icon (top right).
  STEP 3: Click \"Copy KubeConfig to Clipboard\".
  STEP 4: Paste into ~/.kube/config
  STEP 5: Run:  kubectl get pods -n ${namespace}"
    fi

    local card
    card="
╔══════════════════════════════════════════╗
║   ⚓ ADMIRAL BASH'S ISLAND ADVENTURE    ║
║         CREW CREDENTIALS CARD           ║
╚══════════════════════════════════════════╝

  Welcome aboard, ${name}!

  🌐 Rancher UI:  https://rancher.${LAB_DOMAIN}
  👤 Username:    ${rancher_user}
  🔑 Password:    ${password}
  📦 Namespace:   ${namespace}

${kube_steps}

  You are ON THE ISLAND. Good luck, sailor! 🏝️
"
    printf '%s\n' "$card"
    printf '%s\n' "$card" > "$HOME/welcome-aboard.txt"
    echo "   (Saved to ~/welcome-aboard.txt — re-read any time with: cat ~/welcome-aboard.txt)"
}

echo "🌊 Ahoy! Preparing your vessel for Admiral Bash's DevOps Intensive..."
echo "   Lab Domain    : ${LAB_DOMAIN}"
if [[ -n "${SERVER_IP}" ]]; then
    echo "   Lab Server IP : ${SERVER_IP} (will be pinned in /etc/hosts — self-hosted mode)"
else
    echo "   DNS mode      : public (no SERVER_IP set — assuming ${LAB_DOMAIN} resolves via real DNS)"
fi
if [[ -n "${KUBECONFIG_URL:-}" ]]; then
  echo "   Kubeconfig URL: ${KUBECONFIG_URL}"
fi

# ── Who's sailing? ────────────────────────────────────────────
# The end-of-setup credential card is personalized from the student's roster
# username — their first name, lowercased (e.g. "divya"). We ask for it up front
# so the long install runs unattended and the finished card greets them by name.
# An explicit STUDENT env var skips the prompt (headless/instructor runs); the
# prompt is also skipped when there's no terminal so automated runs don't hang.
# `|| true` keeps a Ctrl-D / EOF from tripping `set -e`.
if [[ -z "${STUDENT:-}" && -t 0 ]]; then
  echo ""
  read -rp "🏴 What's your first name, sailor? (as it appears on the crew roster) " _firstname || _firstname=""
  # Normalize to the roster username form: lowercase, no spaces.
  STUDENT="$(printf '%s' "$_firstname" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  STUDENT_NAME="${STUDENT_NAME:-$_firstname}"
fi
if [[ -n "${STUDENT:-}" ]]; then
  echo "   Crew member   : ${STUDENT_NAME:-$STUDENT} (sailor-${STUDENT})"
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

# ── VS Code ───────────────────────────────────────────────────
# Students need a real editor for Dockerfile / YAML / AGENTS.md work. Microsoft's
# `code` package via the official packages.microsoft.com apt repo — the same
# install path code.visualstudio.com/docs/setup/linux documents. Idempotent.
# Skipped silently on non-Debian/Ubuntu hosts (the lab targets Ubuntu 24.04).
echo "🪟 Installing VS Code..."
if command -v code &> /dev/null; then
    echo "   VS Code already installed: $(code --version | head -1)"
elif [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS_LIKE" == *"debian"* ]]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]]; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
            | sudo gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
        sudo chmod a+r /etc/apt/keyrings/packages.microsoft.gpg
    fi
    if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
            | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    fi
    sudo apt-get update
    sudo apt-get install -y code
    echo "   ✅ VS Code installed."
else
    echo "   ⚠️  VS Code auto-install only supported on Debian/Ubuntu — skipping."
fi

# ── VS Code extensions ────────────────────────────────────────
# Pre-install the editor extensions students need across the 4-day curriculum.
# Each install is guarded so one marketplace failure can't abort the bootstrap.
# Runs as the invoking user — `code --install-extension` writes to ~/.vscode/
# (the user's home). If the script is invoked as root (sudo bash setup-client.sh)
# the extensions would land in /root/.vscode, which isn't what we want; skip
# and warn so the student can re-run as themselves.
if command -v code &> /dev/null; then
    if [[ "${EUID}" -eq 0 ]]; then
        echo "🧩 Skipping VS Code extensions — script is running as root (run as your normal user to install)."
    else
        echo "🧩 Installing VS Code extensions..."
        VSCODE_EXTENSIONS=(
            "ms-azuretools.vscode-docker"
            "ms-kubernetes-tools.vscode-kubernetes-tools"
            "redhat.vscode-yaml"
            "oderwat.indent-rainbow"
            "esbenp.prettier-vscode"
        )
        # Snapshot the already-installed list once (one fork instead of N).
        EXISTING_EXTS="$(code --list-extensions 2>/dev/null || true)"
        EXT_INSTALLED=0
        EXT_FAILED=0
        for ext in "${VSCODE_EXTENSIONS[@]}"; do
            if printf '%s\n' "$EXISTING_EXTS" | grep -qix "$ext"; then
                echo "   ↪ Already installed: ${ext}"
            elif code --install-extension "$ext" --force > /dev/null 2>&1; then
                echo "   ✅ Installed: ${ext}"
                EXT_INSTALLED=$((EXT_INSTALLED + 1))
            else
                echo "   ⚠️  Failed: ${ext} (marketplace unreachable?) — non-fatal, install later from the Extensions panel."
                EXT_FAILED=$((EXT_FAILED + 1))
            fi
        done
        if [[ $EXT_INSTALLED -gt 0 ]]; then
            echo "   ⚓ ${EXT_INSTALLED} extension(s) newly installed."
        fi
        if [[ $EXT_FAILED -gt 0 ]]; then
            echo "   ⚠️  ${EXT_FAILED} extension(s) failed — the editor still works, students can install manually."
        fi
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

# ── Boatswain persona wiring ─────────────────────────────────
# The labs introduce a Socratic Boatswain (Day 1) that evolves into an
# Incident Commander (Day 4). Students author the persona in ~/lab/AGENTS.md
# and summon it with `hail` — a tiny wrapper around `aichat -r boatswain`.
#
# aichat 0.30.0 does NOT auto-load AGENTS.md from cwd, and its `.file` REPL
# command is one-turn-only. The only mechanism that holds a persona across
# a full session is `aichat -r <role>` against a role file in
# ~/.config/aichat/roles/. We symlink the role file to the student's
# AGENTS.md so edits flow through transparently.
#
# Idempotent: re-running setup-client.sh does not stomp the student's
# AGENTS.md content (only `touch`es it if missing).
echo "⚓ Wiring the Boatswain persona..."
mkdir -p ~/lab ~/.config/aichat/roles
[ -e ~/lab/AGENTS.md ] || touch ~/lab/AGENTS.md
ln -sf ~/lab/AGENTS.md ~/.config/aichat/roles/boatswain.md

# ── VS Code workspace file ────────────────────────────────────
# Ship a sensible workspace into ~/lab/ so students can open the lab with
# `code ~/lab/lab.code-workspace` and get YAML/Dockerfile settings + the
# extension recommendations already wired up. Idempotent: only copies if
# the file doesn't already exist (so student edits aren't stomped on re-run).
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_TEMPLATE="$SCRIPT_DIR/lab.code-workspace"
if [[ -f "$WORKSPACE_TEMPLATE" && ! -f ~/lab/lab.code-workspace ]]; then
    cp "$WORKSPACE_TEMPLATE" ~/lab/lab.code-workspace
    echo "   ⚓ VS Code workspace placed: ~/lab/lab.code-workspace"
fi

# `hail` wrapper — what students actually type to summon Silas (or, on Day 4,
# the Incident Commander, after they overwrite AGENTS.md). The role-handle
# stays `boatswain` because the file behind the symlink hasn't moved — only
# its contents change. Note: the REPL prompt will read `boatswain>` even on
# Day 4; the lab text flags this so students aren't confused.
sudo tee /usr/local/bin/hail > /dev/null <<'HAILEOF'
#!/bin/bash
# Summon the island's AI persona (Socratic Boatswain → Incident Commander).
# The personality lives in ~/lab/AGENTS.md (symlinked into aichat's roles dir
# by setup-client.sh). Edit that file and re-run `hail` to refresh the rules.
exec aichat -r boatswain "$@"
HAILEOF
sudo chmod +x /usr/local/bin/hail
echo "   ⚓ Boatswain wired: ~/lab/AGENTS.md → ~/.config/aichat/roles/boatswain.md, /usr/local/bin/hail installed."

# ── Git identity ──────────────────────────────────────────────
# Day 3 Lab 02 has students `git commit` to Gitea. Without user.email/user.name
# git refuses the first commit with "Please tell me who you are." Pre-seed
# the globals now from whatever name we have — STUDENT/STUDENT_NAME if the
# crew-name prompt was answered, $USER as a fallback. Skipped if the user has
# already set a git identity (we don't stomp pre-existing config).
if command -v git &> /dev/null; then
    if ! git config --global --get user.email > /dev/null 2>&1; then
        _git_user="${STUDENT:-$USER}"
        _git_name="${STUDENT_NAME:-${STUDENT:-$USER}}"
        git config --global user.email "sailor-${_git_user}@bash.local"
        git config --global user.name  "$_git_name"
        # Quieter default branch — silences the "hint: branch.master" notice and
        # matches GitHub/Gitea defaults that the labs assume.
        git config --global init.defaultBranch main
        echo "   ⚓ Git identity set: ${_git_name} <sailor-${_git_user}@bash.local>"
    else
        echo "   ↪ Git identity already configured — leaving as-is."
    fi
fi

# ── Lab TLS trust ─────────────────────────────────────────────
# The production cluster (${LAB_DOMAIN}) serves a real Let's Encrypt wildcard
# cert — issued by cert-manager via the Cloudflare DNS-01 solver (see
# `just deploy-letsencrypt`). Browsers, CLI tools, and the Docker daemon all
# trust it natively, so NO CA install is needed.
#
# The block below is only for the legacy self-signed-cert fallback (a server
# with no public DNS, using `just cert` / `just push-cert`). It is opt-in:
#   INSTALL_LAB_CA=1 bash setup-client.sh <SERVER_IP>
if [[ "${INSTALL_LAB_CA:-0}" == "1" ]]; then
    echo "🔐 INSTALL_LAB_CA=1 — installing the legacy self-signed lab CA..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
    CA_CERT="${REPO_ROOT}/certs/ca.crt"
    if [[ -f "$CA_CERT" ]]; then
        sudo cp "$CA_CERT" /usr/local/share/ca-certificates/nitic-working-connections-ca.crt
        sudo update-ca-certificates
        echo "   ✅ CA cert installed and trust store updated."
        # Docker's daemon does NOT use the system trust store — it needs a
        # per-registry cert at /etc/docker/certs.d/<host>/ca.crt for Harbor.
        if command -v docker &> /dev/null; then
            HARBOR_HOST="harbor.${LAB_DOMAIN}"
            sudo mkdir -p "/etc/docker/certs.d/${HARBOR_HOST}"
            sudo cp "$CA_CERT" "/etc/docker/certs.d/${HARBOR_HOST}/ca.crt"
            echo "   ✅ Docker daemon will now trust ${HARBOR_HOST}."
        fi
    else
        echo "   ⚠️  INSTALL_LAB_CA=1 but no CA cert at ${CA_CERT} — skipping."
    fi
else
    echo "🔐 TLS: cluster serves a real Let's Encrypt cert — no CA install needed."
fi

# ── Harbor push creds: fetch (optional) ──────────────────────
# Normal student path: the robot creds aren't in the environment, so pull them
# from the URL the instructor pre-staged (HARBOR_CREDS_URL). This means nobody
# hand-types the awkward '$'-laden robot username. Skipped when the creds are
# already set (e.g. `just test-client` injects them) or no URL is configured.
# The file is plain `KEY=value` lines; we parse them LITERALLY (grep + prefix
# strip) so the '$' in the robot name is never shell-expanded.
if [[ -z "${HARBOR_ROBOT_USER:-}" && -n "${HARBOR_CREDS_URL:-}" ]]; then
    echo "🔑 Fetching Harbor push creds from ${HARBOR_CREDS_URL}..."
    if _hc="$(curl -fsSL "${HARBOR_CREDS_URL}" 2>/dev/null)"; then
        _ru_line="$(printf '%s\n' "$_hc" | grep -E '^HARBOR_ROBOT_USER='   | head -1)"
        _rs_line="$(printf '%s\n' "$_hc" | grep -E '^HARBOR_ROBOT_SECRET=' | head -1)"
        HARBOR_ROBOT_USER="${_ru_line#HARBOR_ROBOT_USER=}"
        HARBOR_ROBOT_SECRET="${_rs_line#HARBOR_ROBOT_SECRET=}"
        # Tolerate a quoted file (bootstrap-harbor writes the plain form, but the
        # instructor may have staged the single-quoted lab.env lines verbatim).
        HARBOR_ROBOT_USER="${HARBOR_ROBOT_USER#[\"\']}";   HARBOR_ROBOT_USER="${HARBOR_ROBOT_USER%[\"\']}"
        HARBOR_ROBOT_SECRET="${HARBOR_ROBOT_SECRET#[\"\']}"; HARBOR_ROBOT_SECRET="${HARBOR_ROBOT_SECRET%[\"\']}"
        if [[ -n "${HARBOR_ROBOT_USER}" && -n "${HARBOR_ROBOT_SECRET}" ]]; then
            echo "   ✅ Got push creds for ${HARBOR_ROBOT_USER}."
        else
            echo "   ⚠️  Fetched the file but couldn't parse robot creds from it."
        fi
    else
        echo "   ·  No creds staged at that URL (yet) — skipping. Lab 01 push will need a manual login."
    fi
fi

# ── Harbor login (optional) ───────────────────────────────────
# Day 1 Lab 01 pushes to harbor.${LAB_DOMAIN}/raft-fleet. Harbor ALWAYS requires
# auth to push (a public project only grants anonymous PULL), so we log Docker in
# here with the shared push-robot the instructor minted via `just bootstrap-harbor`.
# Skipped cleanly if the creds weren't passed — the lab just needs a manual login.
HARBOR_HOST="harbor.${LAB_DOMAIN}"
if [[ -n "${HARBOR_ROBOT_USER:-}" && -n "${HARBOR_ROBOT_SECRET:-}" ]]; then
    echo "🔑 Logging Docker into ${HARBOR_HOST} as ${HARBOR_ROBOT_USER}..."
    if docker info > /dev/null 2>&1; then
        # Daemon reachable in this shell — log in directly.
        if echo "${HARBOR_ROBOT_SECRET}" | docker login "${HARBOR_HOST}" -u "${HARBOR_ROBOT_USER}" --password-stdin; then
            echo "   ✅ Docker logged in to Harbor."
        else
            echo "   ⚠️  Harbor login failed — double-check the robot creds."
        fi
    elif command -v sg > /dev/null 2>&1; then
        # Fresh install: $USER was just added to the 'docker' group but THIS shell
        # predates that membership. Run the login with the group active via `sg`
        # so it succeeds now, before the log-out/back-in the next step needs anyway.
        if sg docker -c "echo '${HARBOR_ROBOT_SECRET}' | docker login '${HARBOR_HOST}' -u '${HARBOR_ROBOT_USER}' --password-stdin" 2>/dev/null; then
            echo "   ✅ Docker logged in to Harbor."
        else
            echo "   ⚠️  Harbor login deferred — after you log out and back in, run:"
            echo "       echo '<robot-secret>' | docker login ${HARBOR_HOST} -u '${HARBOR_ROBOT_USER}' --password-stdin"
        fi
    else
        echo "   ⚠️  Docker daemon not reachable yet — after you log out and back in, run:"
        echo "       echo '<robot-secret>' | docker login ${HARBOR_HOST} -u '${HARBOR_ROBOT_USER}' --password-stdin"
    fi
else
    echo "🔑 No HARBOR_ROBOT_USER/SECRET passed — skipping Harbor login."
    echo "   (Lab 01's 'docker push' needs it. Instructor: run 'just bootstrap-harbor',"
    echo "    then re-run this script with the printed creds — or 'just test-client'.)"
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
        KUBECONFIG_READY=1
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

# ── /etc/hosts Injection (self-hosted / no-DNS path only) ────
# Only runs when SERVER_IP is set. The production path (real public DNS on
# wagbiz.org) skips this entirely — DNS does the resolution. Self-hosters
# running k3d-on-laptop or an internal cluster set SERVER_IP to pin every
# lab subdomain at the LAN IP. Idempotent: checks for existing entries.
if [[ -n "${SERVER_IP}" ]]; then
    echo "🗺️  SERVER_IP is set — pinning lab subdomains in /etc/hosts (self-hosted mode)..."

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
else
    echo "🗺️  SERVER_IP unset — using public DNS for ${LAB_DOMAIN} (skipping /etc/hosts)."
fi

echo "⚓ Setup Complete! The shipyard is ready."

# Personalized crew card as the final flourish — only when STUDENT is set.
if [[ -n "${STUDENT:-}" ]]; then
    print_credential_card
fi

echo ""
echo "   Self-check this VM any time:  bash scripts/verify-client.sh"
echo ""
echo "Type 'fish' to drop into your newly configured shell and start the adventure!"
