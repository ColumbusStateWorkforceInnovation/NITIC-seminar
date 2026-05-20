# ============================================================
# ⚓ Admiral Bash's Island Adventure — Justfile
# ============================================================
#
# USAGE:
#   1. Copy lab.env.example → lab.env and fill in your values
#   2. Run `just init` to generate certs and validate config
#   3. Run `just bootstrap-server` to set up K3s on the server
#   4. Run `just push-cert` to load TLS into the cluster
#   5. Run `just provision` to create student accounts
#
# Install just: https://just.systems  (brew install just)
# ============================================================

# Load institution-specific config from lab.env (gitignored)
set dotenv-load := true
set dotenv-filename := "lab.env"

# ── Default Values ──────────────────────────────────────────
# All of these can be overridden in lab.env

LAB_DOMAIN     := env_var_or_default("LAB_DOMAIN",     "nitic2026cbus.voyage")
SERVER_IP      := env_var_or_default("SERVER_IP",      "")
SERVER_USER    := env_var_or_default("SERVER_USER",    "ubuntu")
SERVER_SSH_KEY := env_var_or_default("SERVER_SSH_KEY", "~/.ssh/id_rsa")

ORG_NAME       := env_var_or_default("ORG_NAME",       "National Information Technology Innovation Center")
ORG_UNIT       := env_var_or_default("ORG_UNIT",       "ITIN Working Connections Fleet")
ORG_LOCALITY   := env_var_or_default("ORG_LOCALITY",   "Columbus")
ORG_STATE      := env_var_or_default("ORG_STATE",      "Ohio")
ORG_COUNTRY    := env_var_or_default("ORG_COUNTRY",    "US")

CERT_DAYS      := env_var_or_default("CERT_DAYS",      "20")

AI_MODEL       := env_var_or_default("AI_MODEL",       "gemma3:4b")
AI_API_KEY     := env_var_or_default("AI_API_KEY",     "sk-nitic-admin")

STUDENT_ROSTER := env_var_or_default("STUDENT_ROSTER", "scripts/students.csv")
PASSWORD_PREFIX := env_var_or_default("PASSWORD_PREFIX", "AdmiralBash")

RANCHER_URL    := "https://rancher." + LAB_DOMAIN
RANCHER_TOKEN  := env_var_or_default("RANCHER_TOKEN",  "")

LAB_ADMIN_EMAIL := env_var_or_default("LAB_ADMIN_EMAIL", "admin@" + LAB_DOMAIN)

# ── Computed SSH shorthand ───────────────────────────────────
SSH := "ssh -i " + SERVER_SSH_KEY + " " + SERVER_USER + "@" + SERVER_IP
SCP := "scp -i " + SERVER_SSH_KEY

# ============================================================
# 📋 DEFAULT: Show help
# ============================================================

[private]
default: help

# List all available recipes
help:
    @echo ""
    @echo "  ⚓ Admiral Bash's Island Adventure — Instructor Justfile"
    @echo "  ─────────────────────────────────────────────────────────"
    @echo "  Lab Domain       : {{LAB_DOMAIN}}"
    @echo "  Admin Email      : {{LAB_ADMIN_EMAIL}}"
    @echo "  Server IP        : {{SERVER_IP}}"
    @echo "  Org              : {{ORG_NAME}}"
    @echo "  Cert Days        : {{CERT_DAYS}}"
    @echo "  ─────────────────────────────────────────────────────────"
    @just --list --unsorted
    @echo ""

# ============================================================
# 🚀 SETUP RECIPES
# ============================================================

# [FIRST TIME] Full setup: validate config, generate cert, show next steps
init: check-config check-tools cert
    @echo ""
    @echo "  ✅ Lab initialized!"
    @echo ""
    @echo "  Next steps:"
    @echo "    1. just bootstrap-server   — install K3s on the server"
    @echo "    2. just push-cert          — load TLS cert into cluster"
    @echo "    3. just deploy-core        — apply all k8s manifests"
    @echo "    4. just provision          — create student accounts"
    @echo ""

# Validate that required config values are set
check-config:
    #!/usr/bin/env bash
    set -euo pipefail
    ERRORS=0
    echo "🔍 Checking lab.env configuration..."
    if [[ -z "{{SERVER_IP}}" ]]; then
        echo "  ❌ SERVER_IP is not set in lab.env"
        ERRORS=$((ERRORS+1))
    else
        echo "  ✅ SERVER_IP = {{SERVER_IP}}"
    fi
    if [[ "{{LAB_DOMAIN}}" == "nitic2026cbus.voyage" ]]; then
        echo "  ⚠️  LAB_DOMAIN is still the default (nitic2026cbus.voyage). Change it in lab.env if needed."
    else
        echo "  ✅ LAB_DOMAIN = {{LAB_DOMAIN}}"
    fi
    echo "  ✅ ORG_NAME = {{ORG_NAME}}"
    echo "  ✅ CERT_DAYS = {{CERT_DAYS}}"
    [[ $ERRORS -eq 0 ]] || { echo ""; echo "  Fix errors above in lab.env and re-run."; exit 1; }
    echo "  ✅ Config looks good."

# Verify required tools are installed
check-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    MISSING=0
    echo "🔧 Checking required tools..."
    for tool in openssl kubectl helm ssh scp curl jq; do
        if command -v "$tool" &>/dev/null; then
            echo "  ✅ $tool"
        else
            echo "  ❌ $tool — not found"
            MISSING=$((MISSING+1))
        fi
    done
    [[ $MISSING -eq 0 ]] || { echo ""; echo "  Install missing tools and re-run."; exit 1; }

# ============================================================
# 🔐 CERTIFICATE RECIPES
# ============================================================

# Generate the lab CA and wildcard TLS certificate
cert:
    @echo "🔐 Generating lab certificate ({{CERT_DAYS}} days, {{LAB_DOMAIN}})..."
    @LAB_DOMAIN={{LAB_DOMAIN}} \
     CERT_DAYS={{CERT_DAYS}} \
     ORG_NAME="{{ORG_NAME}}" \
     ORG_UNIT="{{ORG_UNIT}}" \
     ORG_LOCALITY="{{ORG_LOCALITY}}" \
     ORG_STATE="{{ORG_STATE}}" \
     ORG_COUNTRY={{ORG_COUNTRY}} \
     bash scripts/generate-lab-cert.sh

# Copy TLS key+cert to the server and create the Kubernetes secret
push-cert:
    @echo "📦 Pushing TLS cert to {{SERVER_IP}}..."
    {{SCP}} certs/tls.key {{SERVER_USER}}@{{SERVER_IP}}:/tmp/tls.key
    {{SCP}} certs/tls.crt {{SERVER_USER}}@{{SERVER_IP}}:/tmp/tls.crt
    {{SSH}} "kubectl create secret tls wildcard-tls \
        --cert=/tmp/tls.crt \
        --key=/tmp/tls.key \
        -n admin-tools \
        --dry-run=client -o yaml | kubectl apply -f - \
      && rm /tmp/tls.key /tmp/tls.crt \
      && echo '✅ wildcard-tls secret created.'"

# Show cert expiry for the current lab cert
cert-info:
    @echo "📋 Current lab cert:"
    @openssl x509 -in certs/tls.crt -noout -subject -issuer -dates 2>/dev/null \
      || echo "❌ No cert found. Run: just cert"

# ============================================================
# 🖥️  SERVER RECIPES
# ============================================================

# Bootstrap K3s on the remote server (runs setup-remote-k3s-server.sh via SSH)
bootstrap-server:
    @echo "🚢 Bootstrapping K3s on {{SERVER_IP}}..."
    {{SCP}} scripts/setup-remote-k3s-server.sh {{SERVER_USER}}@{{SERVER_IP}}:/tmp/setup-server.sh
    {{SSH}} "sudo bash /tmp/setup-server.sh && rm /tmp/setup-server.sh"

# Apply the wildcard-tls secret, gateway, and all core tool manifests
# Uses envsubst to inject LAB_DOMAIN and LAB_ADMIN_EMAIL into all YAML templates.
deploy-core: push-cert
    @echo "⚙️  Deploying core k8s manifests to {{SERVER_IP}} (domain: {{LAB_DOMAIN}})..."
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/gateway.yaml        | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/gateway-routes.yaml | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/cluster-issuer.yaml | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} AI_MODEL={{AI_MODEL}} AI_API_KEY={{AI_API_KEY}} \
      envsubst < k8s/core-tools/ai-engine.yaml      | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/adminer.yaml        | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/mailpit.yaml        | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/mkdocs.yaml         | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/quiz-app.yaml       | {{SSH}} "kubectl apply -f -"
    @echo "✅ Core manifests applied."

# Pull the AI model into Ollama (runs inside the cluster)
pull-model MODEL=AI_MODEL:
    @echo "🤖 Pulling model '{{MODEL}}' into Ollama..."
    {{SSH}} "kubectl exec -n admin-tools deploy/ollama -- ollama pull {{MODEL}}"

# ============================================================
# 🪝 HELM DEPLOY RECIPES
# ============================================================

# Deploy ArgoCD via Helm (envsubst injects LAB_DOMAIN into values)
deploy-argocd:
    @echo "🐙 Deploying ArgoCD (domain: argocd.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add argo https://argoproj.github.io/argo-helm && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} envsubst < k8s/core-tools/argocd-values.yaml \
      | {{SSH}} "helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace -f -"

# Deploy Gitea via Helm (envsubst injects LAB_DOMAIN)
deploy-gitea:
    @echo "🐙 Deploying Gitea (domain: gitea.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add gitea https://dl.gitea.com/charts && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} envsubst < k8s/core-tools/gitea-values.yaml \
      | {{SSH}} "helm upgrade --install gitea gitea/gitea -n admin-tools --create-namespace -f -"

# Deploy Harbor via Helm (envsubst injects LAB_DOMAIN)
deploy-harbor:
    @echo "⚓ Deploying Harbor (domain: harbor.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add harbor https://helm.goharbor.io && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} envsubst < k8s/core-tools/harbor-values.yaml \
      | {{SSH}} "helm upgrade --install harbor harbor/harbor -n admin-tools --create-namespace -f -"

# Deploy Rancher via Helm (envsubst injects LAB_DOMAIN + LAB_ADMIN_EMAIL)
deploy-rancher:
    @echo "🐄 Deploying Rancher (domain: rancher.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add rancher-stable https://releases.rancher.com/server-charts/stable && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/rancher/rancher-values.yaml \
      | {{SSH}} "helm upgrade --install rancher rancher-stable/rancher -n cattle-system --create-namespace -f -"

# SSH into the server
ssh:
    {{SSH}}

# Stream cluster events (useful for watching deploys)
watch:
    {{SSH}} "kubectl get events -A --watch"

# ============================================================
# 👩‍🎓 STUDENT PROVISIONING RECIPES
# ============================================================

# Provision all students from roster (dry-run first)
provision-dry:
    @echo "🏴‍☠️  Dry run — no changes will be made..."
    RANCHER_URL={{RANCHER_URL}} \
    RANCHER_TOKEN={{RANCHER_TOKEN}} \
    bash scripts/provision-students.sh --roster {{STUDENT_ROSTER}} --dry-run

# Provision all students from roster (live)
provision:
    @echo "⚓ Provisioning students from {{STUDENT_ROSTER}}..."
    RANCHER_URL={{RANCHER_URL}} \
    RANCHER_TOKEN={{RANCHER_TOKEN}} \
    bash scripts/provision-students.sh --roster {{STUDENT_ROSTER}}

# Provision a single student by username
provision-one USERNAME:
    @echo "⚓ Provisioning student: {{USERNAME}}..."
    RANCHER_URL={{RANCHER_URL}} \
    RANCHER_TOKEN={{RANCHER_TOKEN}} \
    bash scripts/provision-students.sh --roster {{STUDENT_ROSTER}} --student {{USERNAME}}

# Reset (delete + re-create) a single student's namespace
reset-student USERNAME:
    @echo "🔄 Resetting student: {{USERNAME}}..."
    RANCHER_URL={{RANCHER_URL}} \
    RANCHER_TOKEN={{RANCHER_TOKEN}} \
    bash scripts/provision-students.sh --roster {{STUDENT_ROSTER}} --reset {{USERNAME}}

# ============================================================
# 🎓 STUDENT CLIENT RECIPE
# ============================================================

# Test setup-client.sh on a target student VM (via SSH)
test-client TARGET_IP:
    @echo "🧪 Running setup-client.sh on {{TARGET_IP}}..."
    scp -i {{SERVER_SSH_KEY}} scripts/setup-client.sh ubuntu@{{TARGET_IP}}:/tmp/setup-client.sh
    scp -i {{SERVER_SSH_KEY}} -r certs ubuntu@{{TARGET_IP}}:/tmp/certs
    ssh -i {{SERVER_SSH_KEY}} ubuntu@{{TARGET_IP}} \
        "SERVER_IP={{SERVER_IP}} LAB_DOMAIN={{LAB_DOMAIN}} bash /tmp/setup-client.sh"

# ============================================================
# 🔁 UTILITY RECIPES
# ============================================================

# Initialize lab.env from the example file
setup-env:
    #!/usr/bin/env bash
    if [[ -f lab.env ]]; then
        echo "⚠️  lab.env already exists. Edit it directly or delete it to regenerate."
    else
        cp lab.env.example lab.env
        echo "✅ Created lab.env from lab.env.example"
        echo "   Edit lab.env with your institution's values, then run: just init"
    fi

# Preview the MkDocs docs site locally with your LAB_DOMAIN injected
serve-docs:
    @echo "📖 Installing MkDocs plugins..."
    @pip install --quiet -r requirements.txt
    @echo "📖 Serving docs at http://localhost:8000 (domain: {{LAB_DOMAIN}})..."
    @LAB_DOMAIN={{LAB_DOMAIN}} mkdocs serve

# Show the /etc/hosts block students need (for manual distribution)
show-hosts:
    @echo ""
    @echo "  # ── Admiral Bash's Island Adventure ──────────────"
    @echo "  # Add this to /etc/hosts on each student VM"
    @echo "  # (setup-client.sh does this automatically)"
    @echo "  {{SERVER_IP}}  rancher.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  argocd.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  gitea.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  harbor.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  grafana.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  ai.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  mailpit.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  docs.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  poll.{{LAB_DOMAIN}}"
    @echo ""

# Clean up generated certs (regenerate with: just cert)
clean-certs:
    @echo "🗑️  Removing generated certs..."
    rm -f certs/ca.crt certs/tls.crt certs/README.md
    @echo "✅ Public certs removed. (Keys were already gitignored.)"
