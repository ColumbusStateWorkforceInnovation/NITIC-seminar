# ============================================================
# ⚓ Admiral Bash's Island Adventure — Justfile
# ============================================================
#
# USAGE (REMOTE server):
#   1. Copy lab.env.example → lab.env and fill in your values
#   2. Run `just init` to validate config and tools
#   3. Run `just bootstrap-server` to set up K3s on the server
#   4. Run `just deploy-cert-manager` then `just deploy-letsencrypt` for TLS
#   5. Run `just deploy-core` to apply the core manifests
#   6. Run `just provision` to create student accounts
#
# Install just: https://just.systems  (brew install just)
# ============================================================

# Load institution-specific config from lab.env (gitignored)
set dotenv-load := true
set dotenv-filename := "lab.env"

# ── Default Values ──────────────────────────────────────────
# All of these can be overridden in lab.env

LAB_DOMAIN     := env_var_or_default("LAB_DOMAIN",     "wagbiz.org")
SERVER_IP      := env_var_or_default("SERVER_IP",      "")
SERVER_USER    := env_var_or_default("SERVER_USER",    "ubuntu")
SERVER_SSH_KEY := env_var_or_default("SERVER_SSH_KEY", "~/.ssh/id_rsa")

ORG_NAME       := env_var_or_default("ORG_NAME",       "National Information Technology Innovation Center")
ORG_UNIT       := env_var_or_default("ORG_UNIT",       "ITIN Working Connections Fleet")
ORG_LOCALITY   := env_var_or_default("ORG_LOCALITY",   "Columbus")
ORG_STATE      := env_var_or_default("ORG_STATE",      "Ohio")
ORG_COUNTRY    := env_var_or_default("ORG_COUNTRY",    "US")

CERT_DAYS      := env_var_or_default("CERT_DAYS",      "20")

# Pin k3s for BOTH the k3d test cluster and the remote server (empty = each
# tool's default). Format: k3s channel string, e.g. v1.35.5+k3s1.
K3S_VERSION    := env_var_or_default("K3S_VERSION",    "")

AI_MODEL       := env_var_or_default("AI_MODEL",       "gemma3:4b")
AI_API_KEY     := env_var_or_default("AI_API_KEY",     "sk-nitic-admin")

STUDENT_ROSTER := env_var_or_default("STUDENT_ROSTER", "scripts/students.csv")
PASSWORD_PREFIX := env_var_or_default("PASSWORD_PREFIX", "AdmiralBash")

RANCHER_URL    := "https://rancher." + LAB_DOMAIN
RANCHER_TOKEN  := env_var_or_default("RANCHER_TOKEN",  "")

LAB_ADMIN_EMAIL := env_var_or_default("LAB_ADMIN_EMAIL", "admin@" + LAB_DOMAIN)

# ── Local vs. Remote target ──────────────────────────────────
# LOCAL = "1" runs recipes against a local k3d cluster; "0" runs them over SSH
# against the remote server. Resolved in precedence order:
#   1. the LOCAL env var, if set — per-terminal override: `LOCAL=1 just deploy-core`
#   2. a target pinned by `just use-local` / `just use-remote`  (.just-target)
#   3. auto-detect — LOCAL when SERVER_IP is blank, REMOTE when it is set
# Testing k3d AND a server at once? Pin with `just use-local` / `use-remote`;
# for two terminals running at the SAME time, `export LOCAL=1` in one so the
# shells stay independent (the env var beats the pinned file).
LOCAL_AUTO := if SERVER_IP == "" { "1" } else { "0" }
LOCAL_PIN  := `cat .just-target 2>/dev/null | tr -d '[:space:]'`
LOCAL := env_var_or_default("LOCAL", if LOCAL_PIN != "" { LOCAL_PIN } else { LOCAL_AUTO })

# ── Computed SSH shorthand ───────────────────────────────────
# In LOCAL mode the "SSH" shim collapses to `bash -c`, so the piped
# `... | {{SSH}} "kubectl apply -f -"` recipes run locally instead of over SSH.
SSH := if LOCAL == "1" { "bash -c" } else { "ssh -i " + SERVER_SSH_KEY + " " + SERVER_USER + "@" + SERVER_IP }
SCP := "scp -i " + SERVER_SSH_KEY

# ── Project-local kubeconfig ─────────────────────────────────
# In LOCAL mode, point every recipe's kubectl/helm at a kubeconfig inside the
# repo (written by `just bootstrap-k3d`). This isolates the lab cluster from
# the global ~/.kube/config and stops a k3s install on the same box from
# hijacking kubectl (its binary defaults to root-only /etc/rancher/k3s/k3s.yaml).
# direnv users get the same path in their shell via .envrc; this line makes
# `just` work with or without direnv. REMOTE mode leaves KUBECONFIG untouched.
export KUBECONFIG := if LOCAL == "1" { justfile_directory() / ".kube" / "config" } else { env_var_or_default("KUBECONFIG", "") }

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
    @echo "  Target Mode      : {{ if LOCAL == "1" { "LOCAL (k3d)" } else { "REMOTE (SSH → " + SERVER_IP + ")" } }}{{ if LOCAL_PIN != "" { "  [pinned — 'just use-auto' to clear]" } else { "  [auto]" } }}"
    @echo "  Server IP        : {{SERVER_IP}}"
    @echo "  Org              : {{ORG_NAME}}"
    @echo "  Cert Days        : {{CERT_DAYS}}"
    @echo "  K3s Version      : {{ if K3S_VERSION == "" { "(default — not pinned)" } else { K3S_VERSION } }}"
    @echo "  ─────────────────────────────────────────────────────────"
    @just --list --unsorted
    @echo ""

# ============================================================
# 🚀 SETUP RECIPES
# ============================================================

# [FIRST TIME] Full setup: validate config and tools, show next steps
init: check-config check-tools
    @echo ""
    @echo "  ✅ Lab initialized!"
    @echo ""
    @echo "  Next steps (REMOTE server):"
    @echo "    1. just bootstrap-server    — install K3s on the server"
    @echo "    2. just deploy-cert-manager — install cert-manager"
    @echo "    3. just deploy-letsencrypt  — issue the Let's Encrypt wildcard cert"
    @echo "    4. just deploy-core         — apply all k8s manifests"
    @echo "    5. just provision           — create student accounts"
    @echo ""
    @echo "  Next steps (LOCAL k3d test loop):"
    @echo "    1. just bootstrap-k3d  — create local k3d cluster + Gateway API"
    @echo "    2. just cert           — generate a self-signed wildcard cert"
    @echo "    3. just push-cert      — load it as the wildcard-tls secret"
    @echo "    4. just deploy-core    — apply all k8s manifests to local k3d"
    @echo ""

# Validate that required config values are set
check-config:
    #!/usr/bin/env bash
    set -euo pipefail
    ERRORS=0
    echo "🔍 Checking lab.env configuration..."
    if [[ "{{LOCAL}}" == "1" ]]; then
        echo "  ✅ LOCAL mode — targeting local k3d cluster (SERVER_IP not required)"
    elif [[ -z "{{SERVER_IP}}" ]]; then
        echo "  ❌ SERVER_IP is not set, and LOCAL=0 is forcing remote — set SERVER_IP, or unset LOCAL for the k3d loop."
        ERRORS=$((ERRORS+1))
    else
        echo "  ✅ SERVER_IP = {{SERVER_IP}}"
    fi
    echo "  ✅ LAB_DOMAIN = {{LAB_DOMAIN}}"
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

# Create the namespaces the core manifests/secrets land in (idempotent).
# gateway.yaml + wildcard-tls live in admin-tools; gateway-routes.yaml also
# carries routes in the argocd and cattle-system namespaces, which must exist
# before those HTTPRoutes can be applied.
ensure-namespaces:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📁 Ensuring namespaces exist (admin-tools, argocd, cattle-system)..."
    for ns in admin-tools argocd cattle-system; do
        {{SSH}} "kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -"
    done

# Copy TLS key+cert to the cluster and create the wildcard-tls secret.
# REMOTE: scp the cert to the server, create the secret over SSH.
# LOCAL: create the secret directly against the local k3d context.
push-cert: ensure-namespaces
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{LOCAL}}" == "1" ]]; then
        echo "📦 Creating wildcard-tls secret in the local k3d cluster..."
        kubectl create secret tls wildcard-tls \
            --cert=certs/tls.crt \
            --key=certs/tls.key \
            -n admin-tools \
            --dry-run=client -o yaml | kubectl apply -f -
        echo "✅ wildcard-tls secret created."
    else
        echo "📦 Pushing TLS cert to {{SERVER_IP}}..."
        {{SCP}} certs/tls.key {{SERVER_USER}}@{{SERVER_IP}}:/tmp/tls.key
        {{SCP}} certs/tls.crt {{SERVER_USER}}@{{SERVER_IP}}:/tmp/tls.crt
        {{SSH}} "kubectl create secret tls wildcard-tls \
            --cert=/tmp/tls.crt \
            --key=/tmp/tls.key \
            -n admin-tools \
            --dry-run=client -o yaml | kubectl apply -f - \
          && rm /tmp/tls.key /tmp/tls.crt \
          && echo '✅ wildcard-tls secret created.'"
    fi

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
    {{SSH}} "sudo env K3S_VERSION='{{K3S_VERSION}}' bash /tmp/setup-server.sh && rm /tmp/setup-server.sh"

# [LOCAL] Bootstrap a local k3d cluster for the test loop.
# Runs setup-k3d-cluster.sh: creates the cluster and enables the Traefik
# Gateway API provider. Then run:
#   just deploy-core
bootstrap-k3d:
    @echo "🚢 Bootstrapping local k3d cluster (admiral-bash-drydock)..."
    bash scripts/setup-k3d-cluster.sh

# Install the Gateway API CRDs + enable the Traefik Gateway provider on the
# CURRENT target cluster (honors LOCAL). Fresh clusters get this automatically
# from the setup scripts — use this to retrofit a cluster that was created
# before this wiring existed (e.g. a k3d cluster already running).
enable-gateway:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "⏳ Waiting for the Gateway API CRDs (shipped by k3s Traefik)..."
    for i in $(seq 1 60); do
      if {{SSH}} "kubectl get crd gatewayclasses.gateway.networking.k8s.io" >/dev/null 2>&1; then break; fi
      sleep 5
    done
    {{SSH}} "kubectl wait --for=condition=Established --timeout=60s crd/gatewayclasses.gateway.networking.k8s.io"
    echo "🚦 Enabling the Traefik Gateway API provider..."
    cat k8s/core-tools/traefik-gateway-config.yaml | {{SSH}} "kubectl apply -f -"
    echo "⏳ Waiting for Traefik to redeploy and create the traefik GatewayClass..."
    for i in $(seq 1 60); do
      if {{SSH}} "kubectl get gatewayclass traefik" >/dev/null 2>&1; then break; fi
      sleep 5
    done
    {{SSH}} "kubectl wait --for=condition=Accepted gatewayclass/traefik --timeout=120s"
    echo "✅ Gateway API is live."

# Apply the gateway and all core tool manifests.
# Uses envsubst to inject LAB_DOMAIN / LAB_ADMIN_EMAIL into the YAML templates.
#
# TLS: the gateway consumes the `wildcard-tls` secret. On a REMOTE deploy that
# secret is created by cert-manager — run `just deploy-cert-manager` and
# `just deploy-letsencrypt` BEFORE this recipe. For a LOCAL k3d test loop, run
# `just cert` + `just push-cert` first to load a self-signed wildcard-tls.
deploy-core: ensure-namespaces
    @echo "⚙️  Deploying core k8s manifests to {{ if LOCAL == "1" { "local k3d cluster" } else { SERVER_IP } }} (domain: {{LAB_DOMAIN}})..."
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/gateway.yaml        | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/gateway-routes.yaml | {{SSH}} "kubectl apply -f -"
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

# Deploy the NVIDIA device plugin so pods can request nvidia.com/gpu
deploy-gpu-plugin:
    @echo "🎮 Ensuring the 'nvidia' RuntimeClass..."
    @printf 'apiVersion: node.k8s.io/v1\nkind: RuntimeClass\nmetadata:\n  name: nvidia\nhandler: nvidia\n' | {{SSH}} "kubectl apply -f -"
    @echo "🎮 Deploying the NVIDIA device plugin..."
    {{SSH}} "helm repo add nvdp https://nvidia.github.io/k8s-device-plugin && helm repo update"
    {{SSH}} "helm upgrade --install nvdp nvdp/nvidia-device-plugin \
      --namespace nvidia-device-plugin --create-namespace \
      --set runtimeClassName=nvidia"

# ============================================================
# 🔐 SSO / IDENTITY RECIPES (Dex)
# ============================================================

# Deploy Dex — centralized OIDC identity (sso.{{LAB_DOMAIN}}) + student roster.
# RESTRICTED envsubst: a bare envsubst would mangle the `$` in the bcrypt
# password hashes inside dex.yaml.
deploy-dex:
    @echo "🔐 Deploying Dex SSO (domain: sso.{{LAB_DOMAIN}})..."
    @LAB_DOMAIN={{LAB_DOMAIN}} envsubst '${LAB_DOMAIN}' < k8s/core-tools/dex.yaml \
      | {{SSH}} "kubectl apply -f -"
    @echo "♻️  Rolling Dex to pick up roster/client changes..."
    -{{SSH}} "kubectl -n admin-tools rollout restart deploy/dex"

# Generate a bcrypt hash for a new Dex roster entry (students-as-code).
# Usage:  just dex-hash 'Their-Password'
dex-hash PASSWORD:
    #!/usr/bin/env bash
    set -euo pipefail
    docker run --rm httpd:2-alpine htpasswd -bnBC 10 "" '{{PASSWORD}}' \
      | tr -d ':\n' | sed 's/^\$2y/\$2a/'
    echo

# Apply OIDC auth to Harbor — POST-INSTALL (the Harbor Helm chart can't do this).
# Run AFTER `just deploy-harbor` and `just deploy-dex`.
harbor-sso:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔐 Switching Harbor to OIDC auth via the config API..."
    curl -fsS -k -u "admin:AdmiralBashIsAwesome" -X PUT \
      "https://harbor.{{LAB_DOMAIN}}/api/v2.0/configurations" \
      -H "Content-Type: application/json" \
      -d '{"auth_mode":"oidc_auth","oidc_name":"Dex","oidc_endpoint":"https://sso.{{LAB_DOMAIN}}","oidc_client_id":"harbor","oidc_client_secret":"harbor-oidc-secret","oidc_scope":"openid,profile,email,groups","oidc_groups_claim":"groups","oidc_auto_onboard":true,"oidc_user_claim":"name","oidc_verify_cert":false}'
    echo
    echo "✅ Harbor OIDC configured — students sign in via 'LOGIN VIA OIDC PROVIDER'."

# Deploy cert-manager via Helm
deploy-cert-manager:
    @echo "🔐 Deploying cert-manager..."
    {{SSH}} "helm repo add jetstack https://charts.jetstack.io && helm repo update"
    {{SSH}} "helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set crds.enabled=true"

# Configure Let's Encrypt with Cloudflare DNS-01 (requires CLOUDFLARE_API_TOKEN env var)
CLOUDFLARE_API_TOKEN := env_var_or_default("CLOUDFLARE_API_TOKEN", "")
deploy-letsencrypt:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "{{CLOUDFLARE_API_TOKEN}}" ]]; then
        echo "❌ CLOUDFLARE_API_TOKEN not set. Export it or add to lab.env."
        exit 1
    fi
    echo "🔐 Creating Cloudflare API secret..."
    {{SSH}} "kubectl create secret generic cloudflare-api-token \
        --from-literal=api-token={{CLOUDFLARE_API_TOKEN}} \
        -n cert-manager --dry-run=client -o yaml | kubectl apply -f -"
    echo "🔐 Creating Let's Encrypt ClusterIssuer..."
    {{SSH}} "kubectl apply -f - <<'EOF'
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: {{LAB_ADMIN_EMAIL}}
        privateKeySecretRef:
          name: letsencrypt-prod-account-key
        solvers:
        - dns01:
            cloudflare:
              apiTokenSecretRef:
                name: cloudflare-api-token
                key: api-token
    EOF"
    echo "🔐 Ensuring admin-tools namespace exists..."
    {{SSH}} "kubectl create namespace admin-tools --dry-run=client -o yaml | kubectl apply -f -"
    echo "🔐 Creating wildcard certificate for *.{{LAB_DOMAIN}}..."
    {{SSH}} "kubectl apply -f - <<'EOF'
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: wildcard-cert
      namespace: admin-tools
    spec:
      secretName: wildcard-tls
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      dnsNames:
      - \"{{LAB_DOMAIN}}\"
      - \"*.{{LAB_DOMAIN}}\"
    EOF"
    echo "✅ Let's Encrypt configured. Check: kubectl get certificate -n admin-tools"

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

# ── Target selection ─────────────────────────────────────────
# Pin which cluster `just` deploys to, so you can keep a k3d test and a remote
# server configured at once without misfiring. Pinning writes .just-target
# (gitignored). A `LOCAL=1` / `LOCAL=0` env var still overrides the pin for a
# single command or a single terminal.

# Pin every following `just` command to the LOCAL k3d cluster.
use-local:
    @printf 1 > .just-target
    @echo "🎯 Target pinned: LOCAL (k3d). Clear with 'just use-auto'."

# Pin every following `just` command to the REMOTE server.
use-remote:
    @printf 0 > .just-target
    @echo "🎯 Target pinned: REMOTE (SSH → {{SERVER_IP}}). Clear with 'just use-auto'."

# Clear the pinned target — fall back to auto-detect (LOCAL when SERVER_IP is blank).
use-auto:
    @rm -f .just-target
    @echo "🎯 Target unpinned — auto-detect (LOCAL when SERVER_IP is blank, else REMOTE)."

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
    @echo "  {{SERVER_IP}}  sso.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  gitea.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  harbor.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  grafana.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  ai.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  mailpit.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  db.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  docs.{{LAB_DOMAIN}}"
    @echo "  {{SERVER_IP}}  poll.{{LAB_DOMAIN}}"
    @echo ""

# Clean up generated certs (regenerate with: just cert)
clean-certs:
    @echo "🗑️  Removing generated certs..."
    rm -f certs/ca.crt certs/tls.crt certs/README.md
    @echo "✅ Public certs removed. (Keys were already gitignored.)"
