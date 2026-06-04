# ============================================================
# ⚓ Admiral Bash's Island Adventure — Justfile
# ============================================================
#
# USAGE (REMOTE server):
#   1. Copy lab.env.example → lab.env and fill in your values
#   2. Run `just init` to validate config and tools
#   3. Run `just bootstrap-server` to set up K3s (+ NVIDIA driver) on the server
#   4. Run `just deploy-gpu-plugin` so pods can schedule the Tesla T4
#   5. Run `just deploy-cert-manager` then `just deploy-letsencrypt` for TLS
#   6. Run `just deploy-core` to apply the core manifests
#   7. Run `just provision` to create student accounts
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

# ── Agent (CPU worker) node ──────────────────────────────────
# Populated from `tofu output -raw agent_public_ip` after the agent VM is up.
# Used only by `just bootstrap-agent`; every other recipe still targets the
# server (the agent has no kubeconfig or admin role).
AGENT_IP       := env_var_or_default("AGENT_IP",       "")
AGENT_USER     := env_var_or_default("AGENT_USER",     SERVER_USER)

ORG_NAME       := env_var_or_default("ORG_NAME",       "National Information Technology Innovation Center")
ORG_UNIT       := env_var_or_default("ORG_UNIT",       "ITIN Working Connections Fleet")
ORG_LOCALITY   := env_var_or_default("ORG_LOCALITY",   "Columbus")
ORG_STATE      := env_var_or_default("ORG_STATE",      "Ohio")
ORG_COUNTRY    := env_var_or_default("ORG_COUNTRY",    "US")

CERT_DAYS      := env_var_or_default("CERT_DAYS",      "20")

# Pin k3s for BOTH the k3d test cluster and the remote server (empty = each
# tool's default). Format: k3s channel string, e.g. v1.35.5+k3s1.
K3S_VERSION    := env_var_or_default("K3S_VERSION",    "")

# HANDOFF NOTE (2026-06-01): default bumped gemma3:4b -> qwen3:8b (stronger, still
# fits the Tesla T4's 16GB VRAM). Override via AI_MODEL in lab.env. See lab.env note.
# AI_MODEL     := env_var_or_default("AI_MODEL",       "gemma3:4b")  # previous default
AI_MODEL       := env_var_or_default("AI_MODEL",       "qwen3:8b")

# ── App admin credentials (SECRETS) ──────────────────────────
# Real values live in lab.env (gitignored) — that is the source of truth.
# The committed default is a non-secret placeholder, so NO password ships in
# Git. The deploy recipes call `_require` and refuse to run until the real
# value is set in lab.env. `just creds` reads these too, so it always mirrors
# lab.env. To set one:  echo 'HARBOR_ADMIN_PASSWORD=...' >> lab.env
SECRET_PLACEHOLDER         := "CHANGE_ME_IN_lab.env"
AI_API_KEY                 := env_var_or_default("AI_API_KEY",                 SECRET_PLACEHOLDER)
HARBOR_ADMIN_PASSWORD      := env_var_or_default("HARBOR_ADMIN_PASSWORD",      SECRET_PLACEHOLDER)
# Harbor push robot for Day 1 Lab 01 — created and written to lab.env by
# `just bootstrap-harbor`. The username contains a literal '$' (Harbor names
# project robots `robot$<project>+<name>`), so lab.env stores it single-quoted
# and every recipe MUST reference it single-quoted too, or the shell eats it.
HARBOR_ROBOT_USER          := env_var_or_default("HARBOR_ROBOT_USER",          "")
HARBOR_ROBOT_SECRET        := env_var_or_default("HARBOR_ROBOT_SECRET",        "")
RANCHER_BOOTSTRAP_PASSWORD := env_var_or_default("RANCHER_BOOTSTRAP_PASSWORD", SECRET_PLACEHOLDER)
GRAFANA_ADMIN_PASSWORD     := env_var_or_default("GRAFANA_ADMIN_PASSWORD",     SECRET_PLACEHOLDER)
GITEA_ADMIN_PASSWORD       := env_var_or_default("GITEA_ADMIN_PASSWORD",       SECRET_PLACEHOLDER)
# One demo password for every Dex SSO account; deploy-dex bcrypt-hashes it at
# apply time, so no hash is committed. Give an account its own password later
# by replacing its `hash:` in dex.yaml with a literal `just dex-hash` value.
DEX_DEMO_PASSWORD          := env_var_or_default("DEX_DEMO_PASSWORD",          SECRET_PLACEHOLDER)

STUDENT_ROSTER := env_var_or_default("STUDENT_ROSTER", "scripts/students.csv")
PASSWORD_PREFIX := env_var_or_default("PASSWORD_PREFIX", "AdmiralBash")

RANCHER_URL    := "https://rancher." + LAB_DOMAIN
RANCHER_TOKEN  := env_var_or_default("RANCHER_TOKEN",  "")
# Pin the Rancher chart version so `deploy-rancher` can't silently jump to a newer
# release mid-course (HANDOFF NOTE 2026-06-02: live cluster runs 2.14.1; stable repo
# already has 2.14.2). Bump deliberately, off-class-days, then re-run deploy-rancher.
RANCHER_VERSION := env_var_or_default("RANCHER_VERSION", "2.14.1")

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
    @echo "  Next steps (REMOTE server) — see README.md for the full guide:"
    @echo "    1.  just bootstrap-server    — install K3s (+ GPU driver) on the server"
    @echo "    1b. just bootstrap-agent     — OPTIONAL: join a CPU worker VM (set AGENT_IP first;"
    @echo "                                    see terraform/agent.tf for the worker VM definition)"
    @echo "    2.  just deploy-gpu-plugin   — advertise the GPU to the scheduler (GPU servers only)"
    @echo "    3.  just deploy-cert-manager — install cert-manager"
    @echo "    4.  just deploy-letsencrypt  — issue the Let's Encrypt wildcard cert"
    @echo "    5.  just deploy-core         — apply the core k8s manifests"
    @echo "    6.  just deploy-dex          — single sign-on (OIDC)"
    @echo "    7.  just deploy-gitea / deploy-harbor / deploy-loki / deploy-argocd / deploy-rancher"
    @echo "    8.  just harbor-sso          — wire Harbor to Dex"
    @echo "    8b. just harbor-mail         — point Harbor's mailer at Mailpit"
    @echo "    9.  just bootstrap-harbor    — create the raft-fleet project + push robot (Day 1 Lab 01)"
    @echo "    10. just deploy-harbor-creds — publish the push token so student VMs auto-login"
    @echo "    11. just pull-model          — pull the AI model into Ollama"
    @echo "    12. just provision           — create students + auto-grant lab RBAC (needs RANCHER_TOKEN)"
    @echo "                                    (runs grant-explorer + grant-gateway for you)"
    @echo "    13. just check-access <name> — verify boundary + cluster-read + httproutes before class"
    @echo "    (deploy-rancher auto-pins server-url; re-run 'just set-rancher-url' if it drifts)"
    @echo ""
    @echo "  Next steps (LOCAL k3d test loop):"
    @echo "    1. just bootstrap-k3d  — create local k3d cluster + Gateway API"
    @echo "    2. just cert           — generate a self-signed wildcard cert"
    @echo "    3. just push-cert      — load it as the wildcard-tls secret"
    @echo "    4. just deploy-core    — apply the core k8s manifests"
    @echo "    5. just deploy-dex     — single sign-on (OIDC)"
    @echo "    6. just deploy-gitea / deploy-harbor / deploy-loki / deploy-argocd / deploy-rancher"
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
    for tool in openssl kubectl helm ssh scp curl jq envsubst; do
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

# Join a CPU worker node to the cluster (runs setup-remote-k3s-agent.sh via SSH).
# Prereqs:
#   - SERVER_IP set in lab.env and the server already bootstrapped.
#   - AGENT_IP set in lab.env. After `cd terraform && tofu apply`, grab it with:
#       echo "AGENT_IP=\"$(cd terraform && tofu output -raw agent_public_ip)\"" >> lab.env
# Effect: agent joins, server is labeled node-role=gpu, worker is labeled
# workload=student. Re-apply ai-engine.yaml after this so Ollama picks up its
# nodeSelector and lands on the GPU node.
bootstrap-agent:
    @if [ -z "{{AGENT_IP}}" ]; then \
        echo "❌ AGENT_IP is not set. After 'tofu apply', add to lab.env:"; \
        echo '   AGENT_IP="$(cd terraform && tofu output -raw agent_public_ip)"'; \
        exit 1; \
    fi
    @if [ -z "{{SERVER_IP}}" ]; then \
        echo "❌ SERVER_IP must be set in lab.env so the agent can find the cluster."; \
        exit 1; \
    fi
    @echo "🔑 Fetching node-token from server {{SERVER_IP}}..."
    @TOKEN=$(ssh -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} 'sudo cat /var/lib/rancher/k3s/server/node-token'); \
        if [ -z "$TOKEN" ]; then echo "❌ Got empty token from server."; exit 1; fi; \
        echo "🚣 Bootstrapping agent on {{AGENT_IP}}..."; \
        scp -i {{SERVER_SSH_KEY}} scripts/setup-remote-k3s-agent.sh {{AGENT_USER}}@{{AGENT_IP}}:/tmp/setup-agent.sh; \
        ssh -i {{SERVER_SSH_KEY}} {{AGENT_USER}}@{{AGENT_IP}} \
            "sudo env K3S_URL='https://{{SERVER_IP}}:6443' K3S_TOKEN=\"$TOKEN\" K3S_VERSION='{{K3S_VERSION}}' bash /tmp/setup-agent.sh && rm /tmp/setup-agent.sh"
    @echo "⏳ Waiting for the new node to register (15s)..."
    @sleep 15
    @{{SSH}} "kubectl get nodes -o wide"
    @echo "🏷️  Labeling nodes (node-role=gpu on server, workload=student on agent)..."
    @SERVER_HOST=$(ssh -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} hostname); \
        AGENT_HOST=$(ssh -i {{SERVER_SSH_KEY}} {{AGENT_USER}}@{{AGENT_IP}} hostname); \
        ssh -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} \
            "kubectl label node $SERVER_HOST node-role=gpu --overwrite && \
             kubectl label node $AGENT_HOST workload=student --overwrite && \
             { kubectl label node $AGENT_HOST nvidia.com/gpu.present- 2>/dev/null || true; }"
    @echo "✅ Agent joined and nodes labeled."
    @echo "   (Any stale nvidia.com/gpu.present label was stripped from the worker"
    @echo "    so the device plugin DaemonSet stays on the GPU node.)"
    @echo ""
    @echo "   NEXT: re-apply core manifests so Ollama picks up its nodeSelector:"
    @echo "     just deploy-core"

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
#
# AI engine: ai-engine.yaml is GPU-enabled (runtimeClassName: nvidia +
# nvidia.com/gpu: 1). In LOCAL k3d mode those two lines are stripped on the fly
# so Ollama falls back to CPU — the MacBook k3d cluster has no GPU.
deploy-core: ensure-namespaces (_require "AI_API_KEY" AI_API_KEY)
    @echo "⚙️  Deploying core k8s manifests to {{ if LOCAL == "1" { "local k3d cluster" } else { SERVER_IP } }} (domain: {{LAB_DOMAIN}})..."
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/gateway.yaml        | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} \
      envsubst < k8s/core-tools/gateway-routes.yaml | {{SSH}} "kubectl apply -f -"
    @LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} AI_MODEL={{AI_MODEL}} AI_API_KEY={{AI_API_KEY}} \
      envsubst < k8s/core-tools/ai-engine.yaml \
      | {{ if LOCAL == "1" { "grep -vE 'runtimeClassName: nvidia|nvidia.com/gpu:|nodeSelector:|node-role: gpu'" } else { "cat" } }} \
      | {{SSH}} "kubectl apply -f -"
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

# Test a Boatswain persona against the LIVE model in seconds — the edit-test loop
# for AGENTS.md. Edit examples/agents-md/*.md (or any AGENTS.md), run this, read
# the reply + auto-checks. No `hail` restart, no guessing which copy is loaded.
# Sources lab.env for the API key. Usage:
#   just test-boatswain
#   just test-boatswain examples/agents-md/day-1-the-salty-boatswain.md "how do I expose a port?"
#   just test-boatswain ~/lab/AGENTS.md "..."        # debug a student's OWN file
test-boatswain FILE="examples/agents-md/day-1-the-salty-boatswain.md" QUESTION="How do I write a Dockerfile for nginx that copies in my index.html?":
    #!/usr/bin/env bash
    set -a; . ./lab.env; set +a
    python3 scripts/test-persona.py "{{FILE}}" --ask "{{QUESTION}}"

# Same, but a canned 3-turn conversation that checks opener rotation + the
# help-vs-refuse balance across turns. Usage: just test-boatswain-convo [FILE]
test-boatswain-convo FILE="examples/agents-md/day-1-the-salty-boatswain.md":
    #!/usr/bin/env bash
    set -a; . ./lab.env; set +a
    python3 scripts/test-persona.py "{{FILE}}" --convo

# The docs-hub pod's git-sync sidecar clones admiral/nitic-seminar @ branch
# `maindeck` from the in-cluster Gitea; if that repo is missing/empty the pod
# CrashLoops (empty /docs/repo → mkdocs can't find mkdocs.yml). This recipe
# creates the repo (idempotent) and pushes THIS repo's current commit to
# maindeck, then nudges the pod. Run it once after `just deploy-gitea`, and
# again whenever you want the live site to catch up to this repo.
# REMOTE only: it pushes over https://gitea.{{LAB_DOMAIN}}, which must resolve
# (LOCAL k3d has no public DNS — port-forward Gitea and push manually instead).
# Seed/refresh the internal Gitea repo that powers docs.{{LAB_DOMAIN}} (run after deploy-gitea)
seed-docs: (_require "GITEA_ADMIN_PASSWORD" GITEA_ADMIN_PASSWORD)
    #!/usr/bin/env bash
    set -euo pipefail
    GP=$(grep -E '^GITEA_ADMIN_PASSWORD=' lab.env | cut -d= -f2-)
    BASE="https://gitea.{{LAB_DOMAIN}}"
    REPO="admiral/nitic-seminar"
    echo "📖 Seeding ${BASE}/${REPO} (branch maindeck) from $(git rev-parse --short HEAD)..."
    # 1. Create the repo if absent (201 = created, 409 = already there — both OK).
    code=$(curl -s -o /dev/null -w '%{http_code}' -u "admiral:${GP}" \
      -X POST "${BASE}/api/v1/user/repos" -H 'Content-Type: application/json' \
      -d '{"name":"nitic-seminar","private":false,"auto_init":false,"description":"MkDocs source for docs.{{LAB_DOMAIN}} (synced by git-sync)"}')
    case "$code" in
      201)     echo "   ✓ repo created" ;;
      409|500) echo "   ✓ repo already exists" ;;   # Gitea v1.x returns 500 on duplicate
      *)       echo "   ❌ repo create failed (HTTP $code)" >&2; exit 1 ;;
    esac
    # 2. Push this repo's current commit to maindeck (creds scrubbed from output).
    EP=$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=""))' "$GP")
    git push "https://admiral:${EP}@gitea.{{LAB_DOMAIN}}/${REPO}.git" HEAD:refs/heads/maindeck \
      2>&1 | sed -E 's#//admiral:[^@]*@#//admiral:***@#g'
    # 3. Make maindeck the default branch (no-op if already set).
    curl -s -o /dev/null -u "admiral:${GP}" -X PATCH "${BASE}/api/v1/repos/${REPO}" \
      -H 'Content-Type: application/json' -d '{"default_branch":"maindeck"}'
    # 4. Nudge the docs-hub pod so it re-syncs now (best-effort; no-op if undeployed).
    {{SSH}} "kubectl rollout restart deploy/docs-hub -n admin-tools" 2>/dev/null || true
    echo "✅ Docs seeded — git-sync pulls within ~10s. Visit https://docs.{{LAB_DOMAIN}}"

# ============================================================
# 🪝 HELM DEPLOY RECIPES
# ============================================================

# [private] Fail fast if a secret is unset / still the placeholder. Used as a
# dependency by the deploy recipes:  deploy-x: (_require "KEY" KEY)
[private]
_require KEY VALUE:
    #!/usr/bin/env bash
    if [[ -z '{{VALUE}}' || '{{VALUE}}' == '{{SECRET_PLACEHOLDER}}' ]]; then
        echo "❌ {{KEY}} is not set — real values live in lab.env (gitignored), not in Git." >&2
        echo "   Set it:  echo '{{KEY}}=your-secret' >> lab.env" >&2
        exit 1
    fi

# Deploy ArgoCD via Helm (envsubst injects LAB_DOMAIN into values)
deploy-argocd:
    @echo "🐙 Deploying ArgoCD (domain: argocd.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add argo https://argoproj.github.io/argo-helm && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} envsubst < k8s/core-tools/argocd-values.yaml \
      | {{SSH}} "helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace -f -"

# Deploy Gitea via Helm (envsubst injects LAB_DOMAIN + admin password)
deploy-gitea: (_require "GITEA_ADMIN_PASSWORD" GITEA_ADMIN_PASSWORD)
    @echo "🐙 Deploying Gitea (domain: gitea.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add gitea https://dl.gitea.com/charts && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} GITEA_ADMIN_PASSWORD='{{GITEA_ADMIN_PASSWORD}}' \
      envsubst < k8s/core-tools/gitea-values.yaml \
      | {{SSH}} "helm upgrade --install gitea gitea/gitea -n admin-tools --create-namespace -f -"

# Deploy Harbor via Helm (envsubst injects LAB_DOMAIN + admin password)
deploy-harbor: (_require "HARBOR_ADMIN_PASSWORD" HARBOR_ADMIN_PASSWORD)
    @echo "⚓ Deploying Harbor (domain: harbor.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add harbor https://helm.goharbor.io && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} HARBOR_ADMIN_PASSWORD='{{HARBOR_ADMIN_PASSWORD}}' \
      envsubst < k8s/core-tools/harbor-values.yaml \
      | {{SSH}} "helm upgrade --install harbor harbor/harbor -n admin-tools --create-namespace -f -"

# Pre-create the Harbor `raft-fleet` project (public) + a push robot for Day 1
# Lab 01. Without this, every student's `docker push` fails with "project
# raft-fleet not found" — and Harbor never allows anonymous PUSH regardless
# (public projects only grant anonymous PULL). The robot creds are written to
# lab.env (gitignored) so `just test-client` and the student bootstrap can
# auto-`docker login`; the public project lets the cluster pull the image with
# no creds in Lab 02. Idempotent — a re-run refreshes the robot secret. Curls
# https://harbor.{{LAB_DOMAIN}} directly, so that host must resolve from where
# you run this (production DNS, not k3d).
# Create the raft-fleet Harbor project + push robot for Day 1 Lab 01 (after deploy-harbor)
bootstrap-harbor: (_require "HARBOR_ADMIN_PASSWORD" HARBOR_ADMIN_PASSWORD)
    #!/usr/bin/env bash
    set -euo pipefail
    BASE="https://harbor.{{LAB_DOMAIN}}"
    PROJECT="raft-fleet"; ROBOT="raft-pusher"
    AUTH=(-u "admin:${HARBOR_ADMIN_PASSWORD}")   # dotenv-load exposes the env var
    echo "⚓ Bootstrapping Harbor project '${PROJECT}' on ${BASE}..."
    # 1. Public project (201 = created, 409 = already there — both fine).
    code=$(curl -sSk -o /dev/null -w '%{http_code}' "${AUTH[@]}" \
      -X POST "${BASE}/api/v2.0/projects" -H 'Content-Type: application/json' \
      -d "{\"project_name\":\"${PROJECT}\",\"metadata\":{\"public\":\"true\"},\"storage_limit\":-1}")
    case "$code" in
      201) echo "   ✓ project '${PROJECT}' created (public)" ;;
      409) echo "   ✓ project '${PROJECT}' already exists" ;;
      *)   echo "   ❌ project create failed (HTTP $code)" >&2; exit 1 ;;
    esac
    # Force public even if it pre-existed as private (no-op otherwise).
    curl -sSk "${AUTH[@]}" -X PUT "${BASE}/api/v2.0/projects/${PROJECT}" \
      -H 'Content-Type: application/json' -d '{"metadata":{"public":"true"}}' >/dev/null || true
    # 2. (Re)create the push robot. Harbor reveals a robot's secret ONLY at
    #    creation, so delete any existing one first to guarantee a usable secret.
    #    Project robots are NOT in the system-level /robots list — listing them
    #    requires a `Level=project,ProjectID=<id>` query, so fetch the id first.
    PID=$(curl -sSk "${AUTH[@]}" "${BASE}/api/v2.0/projects?name=${PROJECT}" \
      | jq -r --arg p "$PROJECT" '.[]? | select(.name==$p) | .project_id' | head -1)
    [[ -n "${PID:-}" ]] || { echo "   ❌ couldn't resolve project id for ${PROJECT}" >&2; exit 1; }
    existing=$(curl -sSk "${AUTH[@]}" --get "${BASE}/api/v2.0/robots" \
      --data-urlencode "q=Level=project,ProjectID=${PID}" --data-urlencode "page_size=100" \
      | jq -r --arg r "$ROBOT" '.[]? | select(.name | endswith("+" + $r)) | .id' | head -1)
    if [[ -n "${existing:-}" ]]; then
      echo "   ↪ refreshing existing robot (id ${existing})"
      curl -sSk "${AUTH[@]}" -X DELETE "${BASE}/api/v2.0/robots/${existing}" >/dev/null
    fi
    resp=$(curl -sSk "${AUTH[@]}" -X POST "${BASE}/api/v2.0/robots" \
      -H 'Content-Type: application/json' \
      -d "{\"name\":\"${ROBOT}\",\"description\":\"Day 1 Lab 01 push token for ${PROJECT}\",\"duration\":-1,\"level\":\"project\",\"permissions\":[{\"kind\":\"project\",\"namespace\":\"${PROJECT}\",\"access\":[{\"resource\":\"repository\",\"action\":\"push\"},{\"resource\":\"repository\",\"action\":\"pull\"}]}]}")
    ROBOT_USER=$(echo "$resp" | jq -r '.name // empty')
    ROBOT_SECRET=$(echo "$resp" | jq -r '.secret // empty')
    [[ -n "$ROBOT_USER" && -n "$ROBOT_SECRET" ]] || { echo "   ❌ robot create failed: $resp" >&2; exit 1; }
    echo "   ✓ robot account: ${ROBOT_USER}"
    # 3. Persist creds to lab.env (gitignored). Single-quoted — the robot name
    #    has a literal '$' that dotenv + the shell must NOT expand. Replace any
    #    prior HARBOR_ROBOT_* lines so re-runs don't pile up.
    touch lab.env
    grep -vE '^HARBOR_ROBOT_(USER|SECRET)=' lab.env > lab.env.tmp 2>/dev/null || true
    printf "HARBOR_ROBOT_USER='%s'\nHARBOR_ROBOT_SECRET='%s'\n" "$ROBOT_USER" "$ROBOT_SECRET" >> lab.env.tmp
    mv lab.env.tmp lab.env
    echo "   ✏️  Wrote HARBOR_ROBOT_USER / HARBOR_ROBOT_SECRET to lab.env"
    # 4. Also emit the stageable artifact (plain KEY=value) for the fetch path:
    #    students' setup-client.sh pulls this from HARBOR_CREDS_URL so nobody
    #    hand-types the '$'-laden robot name. harbor-robot.env is gitignored.
    printf "HARBOR_ROBOT_USER=%s\nHARBOR_ROBOT_SECRET=%s\n" "$ROBOT_USER" "$ROBOT_SECRET" > harbor-robot.env
    echo "   ✏️  Wrote harbor-robot.env (the file to stage for the fetch path)"
    echo ""
    echo "✅ Harbor ready for Lab 01 — students push to ${BASE}/${PROJECT}/<name>:v1."
    echo "   Next: 'just deploy-harbor-creds' publishes harbor-robot.env so each VM"
    echo "   auto-logs-in (setup-client.sh fetches it). Re-run this recipe after the"
    echo "   seminar to rotate the (push-only, throwaway) token."

# Publish the Harbor push-robot creds so student VMs auto-`docker login`. Builds
# the `harbor-creds` ConfigMap from the gitignored harbor-robot.env (NO token in
# Git) and deploys a tiny nginx that serves it at
# https://docs.{{LAB_DOMAIN}}/creds/harbor-robot.env — the URL setup-client.sh
# fetches. Run AFTER `just bootstrap-harbor`. Honors LOCAL/REMOTE.
deploy-harbor-creds:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ -f harbor-robot.env ]] || { echo "❌ harbor-robot.env not found — run 'just bootstrap-harbor' first." >&2; exit 1; }
    echo "📤 Publishing creds at https://docs.{{LAB_DOMAIN}}/creds/harbor-robot.env ..."
    # Build the ConfigMap YAML LOCALLY from the file (kubectl handles escaping, so
    # the '$' in the robot name is safe — no envsubst on the content), then apply
    # it to the target cluster. --dry-run=client doesn't contact a cluster.
    kubectl create configmap harbor-creds \
      --from-file=harbor-robot.env=harbor-robot.env -n admin-tools \
      --dry-run=client -o yaml | {{SSH}} "kubectl apply -f -"
    LAB_DOMAIN={{LAB_DOMAIN}} envsubst < k8s/core-tools/harbor-creds.yaml | {{SSH}} "kubectl apply -f -"
    # Pick up refreshed creds on a re-run (ConfigMap volume updates can lag).
    {{SSH}} "kubectl rollout restart deploy/harbor-creds -n admin-tools" >/dev/null 2>&1 || true
    echo "✅ Published. Verify: curl https://docs.{{LAB_DOMAIN}}/creds/harbor-robot.env"

# Deploy Loki + Grafana via Helm (envsubst injects LAB_DOMAIN + Grafana admin pw)
deploy-loki: (_require "GRAFANA_ADMIN_PASSWORD" GRAFANA_ADMIN_PASSWORD)
    @echo "📊 Deploying loki-stack (Grafana: grafana.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add grafana https://grafana.github.io/helm-charts && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} GRAFANA_ADMIN_PASSWORD='{{GRAFANA_ADMIN_PASSWORD}}' \
      envsubst < k8s/core-tools/loki-stack-values.yaml \
      | {{SSH}} "helm upgrade --install loki-stack grafana/loki-stack -n admin-tools --create-namespace -f -"

# Deploy Rancher via Helm (envsubst injects LAB_DOMAIN + LAB_ADMIN_EMAIL + bootstrap pw)
deploy-rancher: (_require "RANCHER_BOOTSTRAP_PASSWORD" RANCHER_BOOTSTRAP_PASSWORD)
    @echo "🐄 Deploying Rancher (domain: rancher.{{LAB_DOMAIN}})..."
    {{SSH}} "helm repo add rancher-stable https://releases.rancher.com/server-charts/stable && helm repo update"
    LAB_DOMAIN={{LAB_DOMAIN}} LAB_ADMIN_EMAIL={{LAB_ADMIN_EMAIL}} RANCHER_BOOTSTRAP_PASSWORD='{{RANCHER_BOOTSTRAP_PASSWORD}}' \
      envsubst < k8s/rancher/rancher-values.yaml \
      | {{SSH}} "helm upgrade --install rancher rancher-stable/rancher --version {{RANCHER_VERSION}} -n cattle-system --create-namespace -f -"
    @echo "📌 Pinning server-url (so the kubeconfig students copy is deterministic)..."
    @just set-rancher-url || echo "   ⚠️  Rancher not Ready in time — re-run 'just set-rancher-url' once it is."

# Pin Rancher's server-url. The kubeconfig students copy from the Rancher UI
# derives its API-server address from this setting. The Helm `hostname` value is
# supposed to set it on a clean install, but it can drift to EMPTY (e.g. after a
# Rancher reset / stale APIService churn — see the rancher-no-available-server
# note), which makes the copied kubeconfigs fragile / host-dependent. This waits
# for Rancher to create the setting, then enforces it. Idempotent; auto-run by
# deploy-rancher, and safe to re-run any time. Honors LOCAL/REMOTE.
set-rancher-url:
    #!/usr/bin/env bash
    set -uo pipefail
    URL="https://rancher.{{LAB_DOMAIN}}"
    echo "⏳ Waiting for Rancher's server-url setting to exist (up to ~5 min)..."
    ok=""
    for i in $(seq 1 60); do
        if {{SSH}} "kubectl get setting.management.cattle.io server-url" >/dev/null 2>&1; then ok=1; break; fi
        sleep 5
    done
    if [[ "$ok" != "1" ]]; then
        echo "⚠️  server-url setting never appeared — is Rancher Ready? Re-run 'just set-rancher-url' once it is."
        exit 1
    fi
    {{SSH}} "kubectl patch setting.management.cattle.io server-url --type=merge -p '{\"value\":\"${URL}\"}'"
    echo "✅ Rancher server-url pinned to ${URL}"

# Deploy the NVIDIA device plugin so pods can request nvidia.com/gpu
deploy-gpu-plugin:
    @echo "🎮 Ensuring the 'nvidia' RuntimeClass..."
    @printf 'apiVersion: node.k8s.io/v1\nkind: RuntimeClass\nmetadata:\n  name: nvidia\nhandler: nvidia\n' | {{SSH}} "kubectl apply -f -"
    @echo "🎮 Deploying the NVIDIA device plugin..."
    {{SSH}} "helm repo add nvdp https://nvidia.github.io/k8s-device-plugin && helm repo update"
    {{SSH}} "helm upgrade --install nvdp nvdp/nvidia-device-plugin \
      --namespace nvidia-device-plugin --create-namespace \
      --set runtimeClassName=nvidia"
    # The chart's default nodeAffinity expects Node-Feature-Discovery labels
    # (nvidia.com/gpu.present, feature.node.kubernetes.io/pci-10de.present) — but
    # we don't run NFD, so without a matching label the DaemonSet schedules 0 pods
    # and never advertises the GPU, leaving GPU pods (Ollama) stuck Pending.
    #
    # Target ONLY the GPU node so the DaemonSet doesn't try (and fail) to start
    # on the CPU worker. `node-role=gpu` is set by setup-remote-k3s-server.sh
    # when it detects NVIDIA hardware, and re-asserted by bootstrap-agent. If
    # neither has run yet (rare — fresh cluster, no GPU detected), we fall back
    # to labeling all nodes so legacy single-node deploys keep working.
    @echo "🏷️  Labeling GPU node(s) nvidia.com/gpu.present=true so the DaemonSet schedules..."
    {{SSH}} "if kubectl get nodes -l node-role=gpu -o name | grep -q .; then \
        kubectl label nodes -l node-role=gpu nvidia.com/gpu.present=true --overwrite; \
    else \
        echo '   ⚠️  No node has node-role=gpu — falling back to labeling all nodes.'; \
        kubectl label nodes --all nvidia.com/gpu.present=true --overwrite; \
    fi"

# ============================================================
# 🔐 SSO / IDENTITY RECIPES (Dex)
# ============================================================

# Deploy Dex — centralized OIDC identity (sso.{{LAB_DOMAIN}}) + student roster.
# RESTRICTED envsubst: a bare envsubst would mangle the `$` in the bcrypt
# password hashes inside dex.yaml.
deploy-dex: (_require "DEX_DEMO_PASSWORD" DEX_DEMO_PASSWORD)
    #!/usr/bin/env bash
    set -euo pipefail
    # The live roster (k8s/core-tools/dex.yaml) is gitignored — it holds real
    # student names/emails (PII). Only dex.yaml.example (pirates) is committed.
    if [[ ! -f k8s/core-tools/dex.yaml ]]; then
        echo "❌ k8s/core-tools/dex.yaml not found (it's gitignored — holds the real roster)."
        echo "   Create it from the template, then edit in the real roster:"
        echo "     cp k8s/core-tools/dex.yaml.example k8s/core-tools/dex.yaml"
        exit 1
    fi
    echo "🔐 Deploying Dex SSO (domain: sso.{{LAB_DOMAIN}})..."
    # Bcrypt the one demo password at apply time so no hash is committed; every
    # staticPassword in dex.yaml references ${DEX_PASSWORD_HASH}. (Needs Docker.)
    DEX_PASSWORD_HASH=$(docker run --rm httpd:2-alpine htpasswd -bnBC 10 "" '{{DEX_DEMO_PASSWORD}}' | tr -d ':\n' | sed 's/^\$2y/\$2a/')
    # Restricted envsubst: ONLY these two vars — a bare envsubst would eat the
    # `$` in the generated bcrypt hash.
    LAB_DOMAIN='{{LAB_DOMAIN}}' DEX_PASSWORD_HASH="$DEX_PASSWORD_HASH" \
      envsubst '${LAB_DOMAIN} ${DEX_PASSWORD_HASH}' < k8s/core-tools/dex.yaml \
      | {{SSH}} "kubectl apply -f -"
    echo "♻️  Rolling Dex to pick up roster/client changes..."
    {{SSH}} "kubectl -n admin-tools rollout restart deploy/dex" || true

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
harbor-sso: (_require "HARBOR_ADMIN_PASSWORD" HARBOR_ADMIN_PASSWORD)
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔐 Switching Harbor to OIDC auth via the config API..."
    curl -fsS -k -u "admin:{{HARBOR_ADMIN_PASSWORD}}" -X PUT \
      "https://harbor.{{LAB_DOMAIN}}/api/v2.0/configurations" \
      -H "Content-Type: application/json" \
      -d '{"auth_mode":"oidc_auth","oidc_name":"Dex","oidc_endpoint":"https://sso.{{LAB_DOMAIN}}","oidc_client_id":"harbor","oidc_client_secret":"harbor-oidc-secret","oidc_scope":"openid,profile,email,groups","oidc_groups_claim":"groups","oidc_auto_onboard":true,"oidc_user_claim":"name","oidc_verify_cert":false}'
    echo
    echo "✅ Harbor OIDC configured — students sign in via 'LOGIN VIA OIDC PROVIDER'."

# Point Harbor's mailer at Mailpit — POST-INSTALL (the chart has no mail values,
# same config-API story as harbor-sso). Run AFTER `just deploy-harbor`. Harbor is
# in admin-tools alongside Mailpit, but we use the Service FQDN for uniformity.
# Plain SMTP on :1025 — no TLS (email_ssl=false), no auth, skip cert verify.
harbor-mail: (_require "HARBOR_ADMIN_PASSWORD" HARBOR_ADMIN_PASSWORD)
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📧 Pointing Harbor's mailer at Mailpit via the config API..."
    curl -fsS -k -u "admin:{{HARBOR_ADMIN_PASSWORD}}" -X PUT \
      "https://harbor.{{LAB_DOMAIN}}/api/v2.0/configurations" \
      -H "Content-Type: application/json" \
      -d '{"email_host":"mailpit.admin-tools.svc.cluster.local","email_port":1025,"email_from":"Harbor Lab <noreply@{{LAB_DOMAIN}}>","email_username":"","email_password":"","email_ssl":false,"email_insecure":true,"email_identity":""}'
    echo
    echo "✅ Harbor mail → Mailpit. Test it: Administration → Configuration → Email → 'Test Email'."

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
    @echo ""
    @echo "🔐 Granting the RBAC the labs actually need (so provisioning = lab-ready)..."
    @just grant-explorer
    @just grant-gateway
    @echo "   ↪ If grant-gateway 'skipped' a namespace, Rancher hadn't synced its"
    @echo "     rolebinding yet — just re-run 'just grant-gateway' in a few seconds."

# Provision a single student by username
provision-one USERNAME:
    @echo "⚓ Provisioning student: {{USERNAME}}..."
    RANCHER_URL={{RANCHER_URL}} \
    RANCHER_TOKEN={{RANCHER_TOKEN}} \
    bash scripts/provision-students.sh --roster {{STUDENT_ROSTER}} --student {{USERNAME}}
    @echo "🔐 Granting lab RBAC (cluster-read + HTTPRoute)..."
    @just grant-explorer
    @just grant-gateway

# Reset (delete + re-create) a single student's namespace
reset-student USERNAME:
    @echo "🔄 Resetting student: {{USERNAME}}..."
    RANCHER_URL={{RANCHER_URL}} \
    RANCHER_TOKEN={{RANCHER_TOKEN}} \
    bash scripts/provision-students.sh --roster {{STUDENT_ROSTER}} --reset {{USERNAME}}

# Grant students read-only cluster-wide view (namespaces + pods + pod logs).
# Rancher's project-member role is namespace-scoped, but the labs assume students
# can see the whole cluster: Day 1 Lab 02's `kubectl get ns` connectivity check,
# the `kubectl get pods -A` scavenger hunt, and Day 2 Lab 01's k9s `:ns` view all
# return Forbidden without this. Applies a ClusterRole bound to system:authenticated
# (covers every current + future student in one shot). Grants NO secrets and NO
# write outside the student's own namespace — the `check-access` admin boundary
# stays intact. Idempotent; run once after `provision`. Honors LOCAL/REMOTE.
# Grant students read-only cluster view (get ns / pods -A / k9s :ns) — Day 1 Lab 02 + Day 2 Lab 01.
grant-explorer:
    @echo "🔭 Granting students read-only cluster view (student-explorer)..."
    cat k8s/rbac/student-explorer.yaml | {{SSH}} "kubectl apply -f -"
    @echo "✅ Applied. Verify with: just check-access <student>"

# Grant students HTTPRoute access in their OWN namespace — Day 2 Lab 03 Student C
# exposes their frontend via a Gateway API HTTPRoute, but Rancher's project-member
# role omits gateway.networking.k8s.io so the apply 403s. Applies the
# student-gateway-editor ClusterRole, then binds it per student namespace to that
# student's Rancher user (the same identity check-access impersonates) — so it's
# their namespace ONLY, never the admin/infra routes. Idempotent; honors
# LOCAL/REMOTE. Run after `provision`; re-run if you add a student.
grant-gateway:
    #!/usr/bin/env bash
    set -uo pipefail
    echo "🛰️  Granting HTTPRoute (Gateway API) access in student namespaces..."
    cat k8s/rbac/student-gateway.yaml | {{SSH}} "kubectl apply -f -"
    for NS in $({{SSH}} "kubectl get ns -o name" | sed 's#namespace/##' | grep -E '^student-'); do
        SUBJECT=$({{SSH}} "kubectl get rolebindings -n $NS -o json" \
          | jq -r '[.items[].subjects[]? | select(.kind=="User") | .name] | unique | map(select(. != "")) | .[0] // empty')
        if [[ -z "$SUBJECT" ]]; then echo "  ⚠️  $NS: no User subject in RoleBindings — skipped"; continue; fi
        {{SSH}} "kubectl create rolebinding student-gateway --clusterrole=student-gateway-editor --user='$SUBJECT' -n $NS --dry-run=client -o yaml | kubectl apply -f -" >/dev/null
        echo "  ✅ $NS → httproutes for $SUBJECT"
    done
    echo "✅ Done. Verify:  just check-access <student>  (create httproutes should be yes)"

# Grant the cohort-wide "boarding rights" for Day 3 Lab 02 Step 4 (The Raid).
# Students delete/scale/patch a CREWMATE's Deployments + Services and watch that
# crewmate's ArgoCD app self-heal. Rancher's project-member role is namespace-
# scoped, so without this the raid 403s. Applies the student-raider-editor
# ClusterRole, then binds it per student namespace to the system:authenticated
# GROUP — so EVERY student can raid EVERY other student, but the binding never
# lands in admin-tools / argocd / kube-system (admin boundary stays intact).
# Self-Heal must be on for every student Application so the sabotage reverts.
# Idempotent; honors LOCAL/REMOTE. Run after `provision`; revoke with
# `just revoke-raider` once Day 3 is done.
grant-raider:
    #!/usr/bin/env bash
    set -uo pipefail
    echo "🏴‍☠️  Granting cohort-wide raid rights (delete/patch deploy+svc in student namespaces)..."
    cat k8s/rbac/student-raider.yaml | {{SSH}} "kubectl apply -f -"
    for NS in $({{SSH}} "kubectl get ns -o name" | sed 's#namespace/##' | grep -E '^student-'); do
        {{SSH}} "kubectl create rolebinding student-raider --clusterrole=student-raider-editor --group=system:authenticated -n $NS --dry-run=client -o yaml | kubectl apply -f -" >/dev/null
        echo "  ✅ $NS → raidable by the cohort"
    done
    echo "✅ Done. Verify: a student token gets 'yes' on  kubectl auth can-i delete deployment -n student-<someone-else>"

# Revoke the Day 3 raid rights (run after Day 3). Removes the per-namespace
# RoleBindings; leaves the ClusterRole definition in place (harmless unbound).
revoke-raider:
    #!/usr/bin/env bash
    set -uo pipefail
    echo "🧹 Revoking cohort-wide raid rights..."
    for NS in $({{SSH}} "kubectl get ns -o name" | sed 's#namespace/##' | grep -E '^student-'); do
        {{SSH}} "kubectl delete rolebinding student-raider -n $NS --ignore-not-found" >/dev/null
        echo "  ✅ $NS → raid rights removed"
    done
    echo "✅ Done. Per-namespace confinement restored."

# Clear the decks — delete leftover student WORKLOADS so each namespace starts
# Day 3 with its full CPU budget. Every student-<name> namespace has a 500m CPU
# ResourceQuota (≈5 pods at the 100m LimitRange default). Day 2's hand-built
# fleets are still running and eat 200–500m of that, so a fresh Lab 01
# `helm install` (a 3-tier stack, +300m) instantly exceeds quota and pods sit
# Pending — which a novice reads as "I broke it." This deletes Deployments /
# StatefulSets / DaemonSets / ReplicaSets / Pods / Services / HTTPRoutes in every
# student-* namespace. It does NOT touch the namespace, the quota, the
# LimitRange, RoleBindings (incl. student-raider), or secrets. DESTRUCTIVE to
# Day 2 work — that is the intent. Idempotent; honors LOCAL/REMOTE. Run the night
# before Day 3.
clear-decks:
    #!/usr/bin/env bash
    set -uo pipefail
    echo "🧹 Clearing the decks (deleting leftover workloads in student namespaces)..."
    for NS in $({{SSH}} "kubectl get ns -o name" | sed 's#namespace/##' | grep -E '^student-'); do
        {{SSH}} "kubectl delete deploy,statefulset,daemonset,replicaset,pod,service,httproute --all -n $NS --ignore-not-found" >/dev/null 2>&1
        echo "  ✅ $NS cleared"
    done
    echo "✅ Decks cleared. Verify free quota:  kubectl get quota -A | grep student-"

# ============================================================
# 🔥 CHAOS ENGINEERING (DAY 4 — THE PIRATE STRIKES)
# ============================================================
# Day 4 flow (during the 10:10 break):
#   just deploy-chaos-mesh   # once — installs the attack platform
#   just normalize-repos     # Pirate reverts every crew to the FRAGILE baseline
#   just chaos-strike        # recurring pod-kill + pod-failure on every crew
#   just chaos-stress [ns]   # optional CPU-saturation escalation
#   just chaos-status        # confirm experiments are Running
#   just chaos-calm          # KILL SWITCH — stop everything
#   just teardown-chaos-mesh # after class — remove the platform

# Deploy Chaos Mesh via Helm — the Day 4 capstone attack platform. Deliberately
# NOT part of deploy-core: install it during the Day 4 break so the cluster is
# calm until the game starts. Creates the `chaos` namespace where the Pirate's
# experiments live — students can READ them (to name their attacker) but the
# admin boundary keeps them from deleting another namespace's chaos. Honors
# LOCAL/REMOTE. The containerd socket path (k3s/k3d quirk) is in the values file.
deploy-chaos-mesh:
    @echo "🐙 Deploying Chaos Mesh (Day 4 capstone attack platform)..."
    {{SSH}} "helm repo add chaos-mesh https://charts.chaos-mesh.org && helm repo update"
    cat k8s/core-tools/chaos-mesh-values.yaml \
      | {{SSH}} "helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh --create-namespace -f -"
    {{SSH}} "kubectl create namespace chaos --dry-run=client -o yaml | kubectl apply -f -"
    {{SSH}} "kubectl rollout status deploy/chaos-controller-manager -n chaos-mesh --timeout=180s"
    @echo "✅ Chaos Mesh ready. Experiments live in the 'chaos' namespace. Next:  just normalize-repos"

# Pirate sabotage — force-push the canonical FRAGILE island-stack chart onto
# every crew's `maindeck` branch, then ensure each crew's ArgoCD Application
# exists and self-heals. This resets the whole cohort to an identical, known-
# fragile starting line (1 replica, readiness probes off, CPU limits too tight)
# so the chaos attack has the same thing to expose for everyone — and so the
# grading script is deterministic. Mirrors `seed-docs`: pushes over
# https://gitea.{{LAB_DOMAIN}} as the Gitea admin (REMOTE-oriented — for a LOCAL
# k3d test, port-forward Gitea and point BASE at it). Overwriting the crew's
# Day-3 chart history is intentional — that's the sabotage, and they re-harden
# their OWN repo to recover. Idempotent.
normalize-repos: (_require "GITEA_ADMIN_PASSWORD" GITEA_ADMIN_PASSWORD)
    #!/usr/bin/env bash
    set -uo pipefail
    GP=$(grep -E '^GITEA_ADMIN_PASSWORD=' lab.env | cut -d= -f2-)
    EP=$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=""))' "$GP")
    BASE="https://gitea.{{LAB_DOMAIN}}"
    echo "🏴‍☠️  Pirate sabotage — pushing the FRAGILE island-stack to every crew's maindeck..."
    # Build the canonical fragile chart as a throwaway git tree ONCE, then push
    # the same commit into each crew's repo.
    TMP=$(mktemp -d)
    cp -R k8s/chaos/island-stack/. "$TMP/"
    git -C "$TMP" init -q
    git -C "$TMP" add -A
    git -C "$TMP" -c user.email=pirate@lab.local -c user.name=Pirate commit -qm "🏴‍☠️ sabotage: fragile island-stack baseline"
    for NS in $({{SSH}} "kubectl get ns -o name" | sed 's#namespace/##' | grep -E '^student-'); do
        NAME="${NS#student-}"
        # 1. Ensure the repo exists (admin creates it FOR the user if absent).
        code=$(curl -s -o /dev/null -w '%{http_code}' -u "admiral:${GP}" \
          -X POST "${BASE}/api/v1/admin/users/${NAME}/repos" -H 'Content-Type: application/json' \
          -d '{"name":"island-stack","private":false,"auto_init":false}')
        case "$code" in
          201)         echo "  ✓ ${NAME}: repo created" ;;
          409|422|500) : ;;                               # already exists — fine (Gitea v1.x returns 500 on duplicate)
          404)         echo "  ⚠️  ${NAME}: no such Gitea user — skipped"; continue ;;
          *)           echo "  ⚠️  ${NAME}: repo ensure returned HTTP $code (continuing)" ;;
        esac
        # 2. Force-push the fragile chart onto maindeck (creds scrubbed from logs).
        git -C "$TMP" push --force "https://admiral:${EP}@gitea.{{LAB_DOMAIN}}/${NAME}/island-stack.git" HEAD:refs/heads/maindeck \
          2>&1 | sed -E 's#//admiral:[^@]*@#//admiral:***@#g'
        # 3. Make maindeck the default branch (no-op if already set).
        curl -s -o /dev/null -u "admiral:${GP}" -X PATCH "${BASE}/api/v1/repos/${NAME}/island-stack" \
          -H 'Content-Type: application/json' -d '{"default_branch":"maindeck"}'
        # 4. Ensure the crew's self-healing ArgoCD Application exists.
        STUDENT="${NAME}" TARGET_NS="${NS}" envsubst < k8s/chaos/island-stack-app.yaml | {{SSH}} "kubectl apply -f -" >/dev/null
        echo "  🏴‍☠️ ${NAME} sabotaged → fragile island-stack on maindeck; ${NAME}-stack syncing"
    done
    rm -rf "$TMP"
    echo "✅ Sabotage complete. ArgoCD self-heals each crew to the fragile baseline within ~seconds."
    echo "   Verify:  kubectl get applications -n argocd | grep -- -stack"

# Launch the attack — recurring pod-kill + pod-failure against EVERY student
# namespace (per-namespace fan-out, so every crew is hit equally). Both are
# Chaos Mesh Schedules, so they recur for the whole lab until `just chaos-calm`
# deletes them (a bare PodChaos fires only once). pod-kill exposes the single
# replica; pod-failure exposes the missing readiness probe. Honors LOCAL/REMOTE.
chaos-strike:
    #!/usr/bin/env bash
    set -uo pipefail
    echo "☠️  The Pirate strikes — recurring pod-kill + pod-failure across the fleet..."
    HIT=0
    for NS in $({{SSH}} "kubectl get ns -o name" | sed 's#namespace/##' | grep -E '^student-'); do
        TARGET_NS="$NS" envsubst < k8s/chaos/pod-kill.yaml    | {{SSH}} "kubectl apply -f -" >/dev/null
        TARGET_NS="$NS" envsubst < k8s/chaos/pod-failure.yaml | {{SSH}} "kubectl apply -f -" >/dev/null
        echo "  ☠️  $NS under attack"
        HIT=$((HIT+1))
    done
    echo "✅ Attack live on $HIT crew(s). Watch:  just chaos-status   Stop:  just chaos-calm"

# Optional CPU-saturation escalation (exposes the too-tight CPU limit). With no
# argument it stresses every student namespace; pass a name (with or without the
# `student-` prefix) to hit ONE crew — e.g. a team that grade-passed early and is
# bored. DURATION sets how long the StressChaos runs (default 90m). Honors
# LOCAL/REMOTE.  Usage:  just chaos-stress          (all crews)
#                        just chaos-stress blackbeard 30m
chaos-stress NS="" DURATION="90m":
    #!/usr/bin/env bash
    set -uo pipefail
    if [[ -n "{{NS}}" ]]; then
        RAW="{{NS}}"; TARGETS=("student-${RAW#student-}")
    else
        TARGETS=($({{SSH}} "kubectl get ns -o name" | sed 's#namespace/##' | grep -E '^student-'))
    fi
    echo "🔥 CPU stress (duration {{DURATION}}) on: ${TARGETS[*]}"
    for NS in "${TARGETS[@]}"; do
        TARGET_NS="$NS" DURATION="{{DURATION}}" envsubst < k8s/chaos/cpu-stress.yaml | {{SSH}} "kubectl apply -f -" >/dev/null
        echo "  🔥 $NS stressed"
    done
    echo "✅ Stress applied. Stop:  just chaos-calm"

# Show every active chaos experiment cluster-wide (Schedules + their children).
chaos-status:
    @echo "🔎 Active chaos experiments:"
    @{{SSH}} "kubectl get schedule,podchaos,networkchaos,stresschaos -A"

# KILL SWITCH — delete every chaos experiment everywhere. Deletes the Schedules
# AND any PodChaos/NetworkChaos/StressChaos they spawned. Run this the instant
# the room melts down, and at 12:00 to end the game. Idempotent.
chaos-calm:
    @echo "🕊️  Calming the seas — deleting all chaos experiments..."
    @{{SSH}} "kubectl delete schedule,podchaos,networkchaos,stresschaos --all -A --ignore-not-found"
    @echo "✅ All chaos stopped. Pods stabilize within ~a minute."

# Remove Chaos Mesh entirely after class. Stops all chaos first, uninstalls the
# Helm release, and drops the `chaos` namespace. Leaves the cluster as it was.
teardown-chaos-mesh: chaos-calm
    @echo "🧹 Uninstalling Chaos Mesh..."
    -{{SSH}} "helm uninstall chaos-mesh -n chaos-mesh"
    -{{SSH}} "kubectl delete namespace chaos chaos-mesh --ignore-not-found"
    @echo "✅ Chaos Mesh removed."

# Grade a crew's recovery against the RIGHT cluster. The grading script uses
# plain `kubectl`, so a bare `./scripts/grade-cluster-recovery.sh` runs against
# whatever your LAPTOP's kubeconfig points at (often the local k3d) — not the
# class server, which silently reports "namespace not found". This recipe runs
# it locally in LOCAL mode, or copies it to + runs it ON the server in REMOTE
# mode, so it always hits the live cluster. Accepts a bare handle or the full
# namespace.  Usage:  just grade eric   (or  just grade student-eric)
grade CREW:
    #!/usr/bin/env bash
    set -uo pipefail
    RAW="{{CREW}}"; NS="student-${RAW#student-}"
    if [[ "{{LOCAL}}" == "1" ]]; then
        bash scripts/grade-cluster-recovery.sh "$NS"
    else
        {{SCP}} scripts/grade-cluster-recovery.sh {{SERVER_USER}}@{{SERVER_IP}}:/tmp/grade-cluster-recovery.sh >/dev/null
        {{SSH}} "bash /tmp/grade-cluster-recovery.sh $NS"
    fi

# Verify a student's access boundary BEFORE class. Impersonates the Rancher user
# found in their namespace's RoleBindings, then confirms they are DENIED on the
# admin namespaces (secrets + pod-create, the two ways to reach a secret) and
# ALLOWED in their own namespace. This checks the cluster's NATIVE RBAC — what
# the API server itself enforces — so it reflects reality regardless of Rancher.
# Needs your admin kubeconfig (honors LOCAL/REMOTE).  Usage: just check-access blackbeard
check-access USERNAME:
    #!/usr/bin/env bash
    set -uo pipefail
    NS="student-{{USERNAME}}"
    echo "🔎 Access boundary for '{{USERNAME}}'  (namespace: $NS)"
    if ! {{SSH}} "kubectl get namespace $NS" >/dev/null 2>&1; then
        echo "❌ Namespace '$NS' not found. Provision first:  just provision-one {{USERNAME}}"
        exit 1
    fi
    # Discover the exact subject Rancher bound into the student's namespace, so
    # we impersonate the real identity rather than guessing Rancher's naming.
    SUBJECT=$({{SSH}} "kubectl get rolebindings -n $NS -o json" \
      | jq -r '[.items[].subjects[]? | select(.kind=="User") | .name] | unique | map(select(. != "")) | .[0] // empty')
    if [[ -z "$SUBJECT" ]]; then
        echo "❌ No User subject in $NS RoleBindings — is the student bound to their project?"
        exit 1
    fi
    echo "   Impersonating Rancher user: $SUBJECT"
    FAIL=0
    chk () {  # label verb resource namespace expected(yes|no) critical(1|0)
        # A namespace of "-A" checks cluster scope (--all-namespaces); cluster-scoped
        # resources (e.g. namespaces) ignore the -n flag, so passing $NS is harmless.
        local label="$1" verb="$2" res="$3" ns="$4" want="$5" crit="$6" got mark scope
        if [[ "$ns" == "-A" ]]; then scope="--all-namespaces"; else scope="-n $ns"; fi
        got=$({{SSH}} "kubectl auth can-i $verb $res $scope --as=$SUBJECT" 2>/dev/null || true)
        got=${got:-no}
        if [[ "$got" == "$want" ]]; then mark="✅"; else mark="❌"; [[ "$crit" == "1" ]] && FAIL=$((FAIL+1)) || mark="⚠️ "; fi
        printf "   %s  %-42s want=%-3s got=%s\n" "$mark" "$label" "$want" "$got"
    }
    echo ""
    echo "  ── Must be DENIED (the admin boundary) ───────────────────────"
    chk "read secrets in admin-tools"    get    secrets admin-tools   no 1
    chk "read secrets in argocd"         get    secrets argocd        no 1
    chk "read secrets in cattle-system"  get    secrets cattle-system no 1
    chk "read secrets in kube-system"    get    secrets kube-system   no 1
    chk "create pods in admin-tools"     create pods    admin-tools   no 1
    chk "delete pods in another student" delete pods    student-test  no 0
    echo ""
    echo "  ── Should be ALLOWED (their own workspace) ───────────────────"
    chk "create workloads in own ns"     create deployments "$NS"     yes 0
    chk "read secrets in own ns"         get    secrets     "$NS"     yes 0
    # Day 2 Lab 03 Student C exposes their UI via a Gateway API HTTPRoute. Needs
    # `just grant-gateway` (project-member omits gateway.networking.k8s.io).
    chk "create httproutes (Lab 03 UI)"  create httproutes.gateway.networking.k8s.io "$NS" yes 0
    echo ""
    echo "  ── Cluster-wide READ (student-explorer; the labs need it) ────"
    # Day 1 Lab 02 `kubectl get ns` + Day 2 Lab 01 k9s `:ns`. CRITICAL: if the
    # student-explorer ClusterRole isn't applied, these fail and so do the labs.
    chk "list namespaces (get ns / k9s :ns)" list namespaces "$NS"    yes 1
    # Day 1 scavenger hunt `kubectl get pods -A` + reading the hidden pod's logs.
    chk "list pods cluster-wide (-A)"    list   pods       -A         yes 1
    echo ""
    if [[ $FAIL -eq 0 ]]; then
        echo "✅ Boundary intact + cluster-read works — '{{USERNAME}}' is ready for the labs."
    else
        echo "⚠️  $FAIL CRITICAL check(s) FAILED. A DENIED→got=yes means the admin boundary leaks;"
        echo "    a cluster-read ALLOWED→got=no means 'just grant-explorer' hasn't been applied"
        echo "    (Day 1 Lab 02 'get ns' + Day 2 Lab 01 k9s will break). Fix before class."
        exit 1
    fi

# ============================================================
# 🧪 DAY 3 SIDE-QUEST DEMOS — vcluster (dinghy) + KubeVirt (stowaway)
# ============================================================
# Two ~5-minute "whoa" demos you drive from this justfile in front of the room.
# Both target the REMOTE cluster (these Azure nodes have no KVM, so the VM runs
# in software emulation — that's why the VM is tiny CirrOS, not a full desktop).
#
#   vcluster:  just dinghy-up   → dinghy-connect / dinghy-demo → dinghy-down
#   KubeVirt:  just kubevirt-install (ONCE, before class)
#              just stowaway-up → stowaway-ssh / stowaway-vnc → stowaway-down
# See docs/missions/day-03/demos-vcluster-and-kubevirt.md for the run-of-show.

# 🚣 [vcluster] Launch "the dinghy" — a full virtual cluster living inside ONE host namespace (~60s)
dinghy-up:
    @echo "🚣 Launching the dinghy (vcluster '0.34.1' → namespace vcluster-dinghy)..."
    @cat k8s/demos/dinghy-values.yaml | {{SSH}} "helm upgrade --install dinghy vcluster --repo https://charts.loft.sh --version 0.34.1 -n vcluster-dinghy --create-namespace -f - --wait --timeout 5m"
    @echo "✅ The dinghy is afloat."
    @echo "   kubectl to it :  just dinghy-connect   (kubeconfig + tunnel for your laptop)"
    @echo "   the ah-ha     :  just dinghy-demo       (isolation, scripted)"

# 🚣 [vcluster] Fetch the dinghy's kubeconfig to .kube/dinghy.kconfig and hold a tunnel so you can kubectl to it
dinghy-connect:
    #!/usr/bin/env bash
    set -euo pipefail
    [ -n '{{SERVER_IP}}' ] || { echo "❌ SERVER_IP unset — this demo targets the remote cluster."; exit 1; }
    mkdir -p .kube
    echo "🚣 Fetching the dinghy's kubeconfig..."
    # Decode on the server (Linux base64 -d) to avoid macOS base64 flag differences.
    ssh -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} \
      "kubectl -n vcluster-dinghy get secret vc-dinghy -o jsonpath='{.data.config}' | base64 -d" > .kube/dinghy.kconfig
    echo "   ✓ wrote $(pwd)/.kube/dinghy.kconfig (server: https://127.0.0.1:8443)"
    echo ""
    echo "   ▶ In ANOTHER terminal (absolute path — works from any directory):"
    echo "       export KUBECONFIG=$(pwd)/.kube/dinghy.kconfig"
    echo "       kubectl get ns          # a pristine, brand-new 'cluster'"
    echo "       kubectl get nodes       # the dinghy's own (synced) node"
    echo ""
    echo "   Keep THIS terminal open — it holds the tunnel (Ctrl-C to disconnect)."
    # Free a lingering server-side forwarder from a previous run. We target it by
    # PORT (fuser -k 8443/tcp), NOT by command string — a string match would also
    # match this very command and self-kill the shell. Harmless if nothing's bound.
    ssh -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} "fuser -k 8443/tcp 2>/dev/null; sleep 1; true" >/dev/null 2>&1 || true
    # Mac:8443 → server → svc/dinghy:443. Remote port-forward stays foreground.
    ssh -t -L 8443:127.0.0.1:8443 -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} \
      "kubectl -n vcluster-dinghy port-forward svc/dinghy 8443:443"

# 🚣 [vcluster] The ah-ha — create a namespace+deployment INSIDE the dinghy, then show the host can't see it (scripted)
dinghy-demo:
    #!/usr/bin/env bash
    set -uo pipefail
    echo "🚣 Ah-ha: a whole cluster confined to a single host namespace"
    {{SSH}} 'bash -s' <<"SCRIPT"
    set +e
    # Use a dedicated local port (18443) and rewrite the kubeconfig to match, so
    # this never collides with a `dinghy-connect` tunnel (which holds 8443).
    kubectl -n vcluster-dinghy get secret vc-dinghy -o jsonpath="{.data.config}" | base64 -d | sed 's#https://localhost:8443#https://127.0.0.1:18443#' > /tmp/dinghy.kconfig
    pkill -f "port-forward svc/dinghy 18443" 2>/dev/null; sleep 1
    kubectl -n vcluster-dinghy port-forward svc/dinghy 18443:443 >/tmp/dinghy-pf.log 2>&1 &
    PF=$!; trap "kill $PF 2>/dev/null" EXIT
    sleep 5
    export KUBECONFIG=/tmp/dinghy.kconfig
    for i in $(seq 1 12); do kubectl get ns >/dev/null 2>&1 && break; sleep 2; done
    echo; echo "### INSIDE the dinghy — looks like its own fresh cluster ###"
    kubectl get ns
    echo; echo "### Create a namespace + deployment INSIDE the dinghy ###"
    kubectl create namespace treasure-island 2>/dev/null
    kubectl -n treasure-island create deployment grog --image=nginx 2>/dev/null
    sleep 4
    kubectl get ns | grep -E "NAME|treasure-island"
    kubectl -n treasure-island get pods
    unset KUBECONFIG
    echo; echo "### Now look at the HOST cluster ###"
    echo "-- host namespaces: there is NO 'treasure-island' (it's virtual) --"
    kubectl get ns | grep -i treasure-island || echo "   (none on the host ✔)"
    echo "-- the dinghy + EVERYTHING in it is just pods in one namespace --"
    kubectl -n vcluster-dinghy get pods
    SCRIPT
    echo "✅ A full cluster — its nodes, namespaces, workloads — lived inside ONE host namespace."

# 🚣 [vcluster] Scuttle the dinghy (helm uninstall + drop the namespace)
dinghy-down:
    @echo "🧹 Scuttling the dinghy..."
    -@{{SSH}} "helm uninstall dinghy -n vcluster-dinghy"
    -@{{SSH}} "kubectl delete namespace vcluster-dinghy --ignore-not-found --wait=false"
    @echo "✅ Dinghy gone."

# 🧬 [KubeVirt] ONE-TIME prep (run before class, ~4 min): install KubeVirt in emulation mode + virtctl + 'demos' ns
kubevirt-install:
    #!/usr/bin/env bash
    set -euo pipefail
    VER=v1.8.3
    echo "🧬 Installing KubeVirt $VER (software-emulation mode — these nodes have no KVM)..."
    {{SSH}} "kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$VER/kubevirt-operator.yaml"
    cat k8s/demos/kubevirt-cr.yaml | {{SSH}} "kubectl apply -f -"
    echo "⏳ Waiting for KubeVirt to become Available (a few minutes)..."
    {{SSH}} "kubectl -n kubevirt wait kv/kubevirt --for=condition=Available --timeout=420s"
    echo "🔧 Ensuring virtctl is on the server (used by stowaway-ssh / stowaway-vnc)..."
    {{SSH}} "command -v virtctl >/dev/null || { sudo curl -fsSL -o /usr/local/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/$VER/virtctl-$VER-linux-amd64 && sudo chmod +x /usr/local/bin/virtctl; }"
    {{SSH}} "kubectl create namespace demos --dry-run=client -o yaml | kubectl apply -f -"
    echo "✅ KubeVirt ready. Boot the demo VM live with:  just stowaway-up"

# 🫥 [KubeVirt] Boot "the stowaway" — a real CirrOS VM running as a pod (~60-90s to log in)
stowaway-up:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🫥 Smuggling the stowaway aboard (CirrOS VM under software emulation)..."
    {{SSH}} "kubectl create namespace demos --dry-run=client -o yaml | kubectl apply -f -"
    cat k8s/demos/stowaway-vm.yaml | {{SSH}} "kubectl apply -f -"
    echo "⏳ Waiting for the VM to reach Running (then ~60-90s more to finish booting)..."
    {{SSH}} "for i in \$(seq 1 45); do [ \"\$(kubectl -n demos get vmi stowaway -o jsonpath='{.status.phase}' 2>/dev/null)\" = Running ] && break; sleep 4; done"
    {{SSH}} "kubectl -n demos get vmi stowaway -o wide"
    echo "✅ Stowaway is up.   SSH in:  just stowaway-ssh    |    Its screen (VNC):  just stowaway-vnc"

# 🫥 [KubeVirt] SSH into the stowaway (password: treasure) — proves it's a real machine with its own kernel
stowaway-ssh:
    #!/usr/bin/env bash
    set -euo pipefail
    [ -n '{{SERVER_IP}}' ] || { echo "❌ SERVER_IP unset — this demo targets the remote cluster."; exit 1; }
    echo "🔑 SSH into the stowaway — when prompted, the password is:  treasure"
    echo "   (try: uname -a   |   cat /etc/os-release   |   exit to leave)"
    # Free a lingering forwarder on :2222 by PORT (no command-string self-match).
    ssh -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} "fuser -k 2222/tcp 2>/dev/null; sleep 1; true" >/dev/null 2>&1 || true
    # Single-quoted remote string → $! / $PF expand on the SERVER. The remote
    # command runs as an argument (NOT piped on stdin), so the PTY from -t flows
    # to the inner ssh and the interactive password prompt works.
    REMOTE='virtctl port-forward vm/stowaway -n demos 2222:22 >/tmp/stowaway-pf.log 2>&1 & PF=$!; trap "kill $PF 2>/dev/null" EXIT; sleep 4; ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cirros@127.0.0.1'
    ssh -t -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} "$REMOTE"

# 🫥 [KubeVirt] VNC to the stowaway's screen — opens macOS Screen Sharing on the VM's graphical console
stowaway-vnc:
    #!/usr/bin/env bash
    set -euo pipefail
    [ -n '{{SERVER_IP}}' ] || { echo "❌ SERVER_IP unset — this demo targets the remote cluster."; exit 1; }
    echo "🖥️  Opening a VNC tunnel to the stowaway's console (Ctrl-C here to disconnect)..."
    # Free a lingering proxy on :5901 by PORT (no command-string self-match).
    ssh -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} "fuser -k 5901/tcp 2>/dev/null; sleep 1; true" >/dev/null 2>&1 || true
    # Fire the local VNC viewer once the tunnel is up; ssh -L holds it open.
    ( sleep 6; open vnc://127.0.0.1:5901 >/dev/null 2>&1 || echo "   → open vnc://localhost:5901 in your VNC client" ) &
    ssh -t -L 5901:127.0.0.1:5901 -i {{SERVER_SSH_KEY}} {{SERVER_USER}}@{{SERVER_IP}} \
      "virtctl vnc stowaway -n demos --proxy-only --port 5901"

# 🫥 [KubeVirt] Show the stowaway's VM / VMI / launcher-pod status
stowaway-status:
    @{{SSH}} "kubectl -n demos get vm,vmi -o wide; echo; kubectl -n demos get pods -l kubevirt.io/vm=stowaway -o wide"

# 🫥 [KubeVirt] Send the stowaway overboard (delete the VM; leaves KubeVirt + the 'demos' ns in place)
stowaway-down:
    @echo "🧹 Sending the stowaway overboard..."
    -@{{SSH}} "kubectl -n demos delete vm stowaway --ignore-not-found"
    @echo "✅ Stowaway VM deleted. (Re-boot it any time with: just stowaway-up)"

# 🧬 [KubeVirt] Remove KubeVirt entirely (after the seminar). Deletes the VM, the CR, then the operator.
kubevirt-uninstall:
    #!/usr/bin/env bash
    set -uo pipefail
    VER=v1.8.3
    echo "🧹 Removing KubeVirt..."
    {{SSH}} "kubectl -n demos delete vm --all --ignore-not-found" 2>/dev/null || true
    {{SSH}} "kubectl delete kubevirt kubevirt -n kubevirt --ignore-not-found --timeout=120s" 2>/dev/null || true
    {{SSH}} "kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/$VER/kubevirt-operator.yaml --ignore-not-found" 2>/dev/null || true
    {{SSH}} "kubectl delete namespace demos --ignore-not-found --wait=false" 2>/dev/null || true
    echo "✅ KubeVirt removed (virtctl binary left on the server; harmless)."

# ============================================================
# 🎓 STUDENT CLIENT RECIPE
# ============================================================

# Test setup-client.sh on a target student VM (via SSH)
test-client TARGET_IP:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧪 Running setup-client.sh on {{TARGET_IP}}..."
    scp -i {{SERVER_SSH_KEY}} scripts/setup-client.sh ubuntu@{{TARGET_IP}}:/tmp/setup-client.sh
    scp -i {{SERVER_SSH_KEY}} -r certs ubuntu@{{TARGET_IP}}:/tmp/certs
    # Capture the secrets into bash vars first (just fills placeholders inside
    # single quotes → literal, so the '$' in the robot username survives). Then
    # build the remote command with the values single-quoted IN the string, so the
    # remote shell also keeps the '$' literal. ssh "$remote" passes it as one arg
    # without re-expanding (a variable's value isn't recursively expanded). This
    # nesting is why test-client is a script recipe and not a one-line ssh.
    ai='{{AI_API_KEY}}'; ru='{{HARBOR_ROBOT_USER}}'; rs='{{HARBOR_ROBOT_SECRET}}'
    remote="SERVER_IP='{{SERVER_IP}}' LAB_DOMAIN='{{LAB_DOMAIN}}' AI_API_KEY='${ai}'"
    remote="${remote} HARBOR_ROBOT_USER='${ru}' HARBOR_ROBOT_SECRET='${rs}'"
    remote="${remote} bash /tmp/setup-client.sh"
    ssh -i {{SERVER_SSH_KEY}} ubuntu@{{TARGET_IP}} "$remote"

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

# Render the seminar slide decks (Marp → HTML + PDF) into docs/slides/ so they
# ship inside the MkDocs site — the docs pod just git-syncs + `mkdocs serve`, so
# the rendered HTML must be committed under docs/ to appear on the deployed site.
# Also (re)generates docs/slides/index.md, the gallery page linked from the nav.
# Uses npx to fetch the Marp CLI if it isn't installed globally. PDF export
# needs a Chrome/Chromium install. Run after editing any deck under slides/.
slides:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🪧  Rendering slide decks with Marp..."
    cd slides
    out_dir="../docs/slides"
    mkdir -p "$out_dir"
    shopt -s nullglob
    MARP="npx --yes @marp-team/marp-cli@4"
    for deck in */*.md; do
      flat="$(echo "${deck%.md}" | tr '/' '-')"
      echo "  → ${deck}"
      $MARP --no-stdin "${deck}" -o "${out_dir}/${flat}.pdf"
      $MARP --no-stdin "${deck}" -o "${out_dir}/${flat}.html"
    done

    echo "🗂  Generating gallery (docs/slides/index.md)..."
    declare -A day_titles=(
      [day-01]="The Ship Has Sunk"
      [day-02]="Meet the Crew"
      [day-03]="Automated Shipyards"
      [day-04]="The Admiral's Challenge"
    )
    index="${out_dir}/index.md"
    {
      echo "# Slide Decks"
      echo
      echo "The Marp briefing decks for each day. **View** opens a deck in your browser"
      echo "(press \`F\` for fullscreen, arrow keys to navigate); **PDF** is the printable copy."
      echo
      echo "> Auto-generated by \`just slides\` — edit the decks under \`slides/\`, not this page."
    } > "$index"

    last_day=""
    for deck in day-*/*.md; do
      day="${deck%%/*}"
      if [[ "$day" != "$last_day" ]]; then
        num=$((10#${day#day-}))
        title="${day_titles[$day]:-}"
        echo >> "$index"
        if [[ -n "$title" ]]; then
          echo "## Day ${num} — ${title}" >> "$index"
        else
          echo "## Day ${num}" >> "$index"
        fi
        last_day="$day"
      fi
      flat="$(echo "${deck%.md}" | tr '/' '-')"
      # Deck title = first level-1 heading, falling back to the filename.
      heading="$(grep -m1 '^# ' "$deck" | sed 's/^# //')"
      [[ -z "$heading" ]] && heading="${deck##*/}"
      echo "- **${heading}** — [View](${flat}.html){ target=\"_blank\" } · [PDF](${flat}.pdf){ target=\"_blank\" }" >> "$index"
    done

    echo "✅  Decks + gallery rendered to docs/slides/"

# Print the admin credentials for every app in the cluster (read-only).
# Static passwords are the defaults baked into the k8s/ values files; ArgoCD's
# initial admin password is generated at install time and read live from its
# secret. Honors LOCAL/REMOTE for the live lookups.
creds:
    #!/usr/bin/env bash
    set -uo pipefail
    D="{{LAB_DOMAIN}}"
    echo ""
    echo "  🔑 Admiral Bash — Admin Credentials   (domain: $D)"
    echo "  ──────────────────────────────────────────────────────────────"
    printf "  %-8s  %-26s  %-9s  %s\n" "APP" "URL" "USERNAME" "PASSWORD"
    printf "  %-8s  %-26s  %-9s  %s\n" "Harbor"  "https://harbor.$D"  "admin"    '{{HARBOR_ADMIN_PASSWORD}}'
    printf "  %-8s  %-26s  %-9s  %s\n" "Rancher" "https://rancher.$D" "admin"    '{{RANCHER_BOOTSTRAP_PASSWORD}}'
    printf "  %-8s  %-26s  %-9s  %s\n" "Grafana" "https://grafana.$D" "admin"    '{{GRAFANA_ADMIN_PASSWORD}}'
    printf "  %-8s  %-26s  %-9s  %s\n" "Gitea"   "https://gitea.$D"   "admiral"  '{{GITEA_ADMIN_PASSWORD}}'
    printf "  %-8s  %-26s  %-9s  %s\n" "AI/LLM"  "https://ai.$D"      "(bearer)" '{{AI_API_KEY}}'
    printf "  %-8s  %-26s  %-9s  %s\n" "SSO/Dex" "https://sso.$D"     "admiral"  '{{DEX_DEMO_PASSWORD}}'
    # ArgoCD's initial admin password is created at install and lives in a secret.
    ARGO=$({{SSH}} "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'" 2>/dev/null | openssl base64 -d -A 2>/dev/null || true)
    [[ -z "$ARGO" ]] && ARGO="(not found — ArgoCD not deployed yet, or password rotated)"
    printf "  %-8s  %-26s  %-9s  %s\n" "ArgoCD"  "https://argocd.$D"  "admin"    "$ARGO"
    echo "  ──────────────────────────────────────────────────────────────"
    echo "  SSO/Dex logins (all password '{{DEX_DEMO_PASSWORD}}'):"
    # Read the live roster straight from dex.yaml so this never drifts from the
    # source of truth — the staticPasswords `username:` lines, comma-joined.
    # The live file is gitignored (real names); fall back to the committed
    # pirate template on a fresh clone where it hasn't been created yet.
    DEXF=k8s/core-tools/dex.yaml; [[ -f $DEXF ]] || DEXF=$DEXF.example
    USERS=$(grep -E '^\s+username:' "$DEXF" | sed -E 's/.*username:[[:space:]]*"?([^"]+)"?.*/\1/' | paste -sd, - | sed 's/,/, /g')
    echo "    ${USERS:-(none — check k8s/core-tools/dex.yaml)}"
    echo ""
    echo "  ⛵ Student Rancher login → kubeconfig (the Day 1 Lab 02 'board the cluster' flow):"
    echo "    1. Browse to https://rancher.$D and sign in:"
    echo "         username:  sailor-<name>             (e.g. sailor-divya)"
    echo "         password:  {{PASSWORD_PREFIX}}-<name>    (e.g. {{PASSWORD_PREFIX}}-divya)"
    echo "    2. Profile icon (top-right) → \"Copy KubeConfig to Clipboard\""
    echo "    3. Paste into ~/.kube/config, then verify:  kubectl get ns"
    echo "       (each student's workspace is the namespace  student-<name>)"
    echo "    Per-student card with these steps:  scripts/provision-students.sh writes one to /tmp/creds/"
    echo ""
    echo "  Harbor push robot (Day 1 Lab 01 — created by 'just bootstrap-harbor'):"
    # Single-quoted: the robot username has a literal '$' that bash (set -u) would
    # otherwise try to expand. just fills the placeholder in regardless of quoting.
    if [[ -n '{{HARBOR_ROBOT_USER}}' ]]; then
        echo '    user:   {{HARBOR_ROBOT_USER}}'
        echo '    secret: {{HARBOR_ROBOT_SECRET}}'
    else
        echo "    (not provisioned yet — run 'just bootstrap-harbor')"
    fi
    echo ""

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
