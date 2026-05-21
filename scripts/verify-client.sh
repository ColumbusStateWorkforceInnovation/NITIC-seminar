#!/bin/bash
# ============================================================
# ⚓ Admiral Bash's Island Adventure — Client VM Self-Check
# ============================================================
#
# PURPOSE:
#   Verifies a student/client VM after setup-client.sh has run:
#   the lab tools, Docker, the lab CA, /etc/hosts, the aichat and
#   Fish configs, Harbor registry trust, and HTTPS connectivity to
#   the lab cluster through the Gateway.
#
#   Read-only — installs nothing, needs no sudo. Safe to re-run.
#
# USAGE:
#   bash scripts/verify-client.sh
#
# OPTIONAL ENV:
#   LAB_DOMAIN   Override the lab domain (default: nitic2026cbus.voyage).
#
# EXIT CODE:
#   0 — every client-side check passed (warnings allowed).
#   1 — at least one client-side check failed.
#   Warnings cover things that aren't the client's fault (a lab
#   service down, a route not deployed) — they don't fail the run.
# ============================================================

LAB_DOMAIN="${LAB_DOMAIN:-nitic2026cbus.voyage}"

PASS=0
WARN=0
FAIL=0

pass()    { echo "  ✅ $*"; PASS=$((PASS + 1)); }
warn()    { echo "  ⚠️  $*"; WARN=$((WARN + 1)); }
fail()    { echo "  ❌ $*"; FAIL=$((FAIL + 1)); }
info()    { echo "  ·  $*"; }
section() { echo; echo "── $* ──────────────────────────────────"; }

echo ""
echo "⚓ Admiral Bash — Client VM Self-Check"
echo "   Lab domain: ${LAB_DOMAIN}"

# ── System ──────────────────────────────────────────────────
section "System"
if [ -f /etc/os-release ]; then
    info "OS:   $(. /etc/os-release && echo "$PRETTY_NAME")"
else
    info "OS:   $(uname -s)"
fi
info "Arch: $(uname -m)"

# ── Lab tools ───────────────────────────────────────────────
# Confirms each tool setup-client.sh installs is on PATH and
# actually executes — a wrong-architecture binary fails here.
section "Lab tools"
check_tool() {
    local name="$1"
    shift
    if ! command -v "$name" > /dev/null 2>&1; then
        fail "${name} — not installed"
        return
    fi
    local out
    out="$("$name" "$@" 2>&1 | head -1)"
    if echo "$out" | grep -qiE "exec format error|cannot execute binary"; then
        fail "${name} — wrong architecture (won't execute)"
    else
        pass "${name} — ${out}"
    fi
}
check_tool fish     --version
check_tool starship --version
check_tool docker   --version
check_tool kubectl  version --client
check_tool helm     version --short
check_tool k9s      version
check_tool d2       --version
check_tool aichat   --version

# ── Docker daemon ───────────────────────────────────────────
section "Docker daemon"
if ! command -v docker > /dev/null 2>&1; then
    fail "docker not installed"
elif docker info > /dev/null 2>&1; then
    pass "docker daemon reachable"
elif docker info 2>&1 | grep -qi "permission denied"; then
    warn "docker daemon: permission denied — log out and back in, or run 'newgrp docker'"
else
    fail "docker daemon not reachable (is it running?)"
fi

# ── Lab CA certificate ──────────────────────────────────────
section "Lab CA certificate"
CA_FILE="/usr/local/share/ca-certificates/nitic-working-connections-ca.crt"
if [ -f "$CA_FILE" ]; then
    ca_subj="$(openssl x509 -in "$CA_FILE" -noout -subject 2>/dev/null | sed 's/^subject=//')"
    ca_exp="$(openssl x509 -in "$CA_FILE" -noout -enddate 2>/dev/null | cut -d= -f2)"
    pass "lab CA installed —${ca_subj}"
    if openssl x509 -in "$CA_FILE" -noout -checkend 0 > /dev/null 2>&1; then
        info "valid — expires ${ca_exp}"
    else
        fail "lab CA has EXPIRED (${ca_exp}) — regenerate with 'just cert' and redistribute"
    fi
else
    fail "lab CA not found at ${CA_FILE} — setup-client.sh CA step did not run"
fi

# ── /etc/hosts lab entries ──────────────────────────────────
section "/etc/hosts lab entries"
LAB_HOSTS="rancher argocd gitea harbor grafana ai mailpit db docs poll"
hosts_total=0
hosts_found=0
server_ip=""
for h in $LAB_HOSTS; do
    hosts_total=$((hosts_total + 1))
    hline="$(grep -F "${h}.${LAB_DOMAIN}" /etc/hosts 2>/dev/null | head -1)"
    if [ -n "$hline" ]; then
        hosts_found=$((hosts_found + 1))
        [ -z "$server_ip" ] && server_ip="$(echo "$hline" | awk '{print $1}')"
    fi
done
if [ "$hosts_found" -eq "$hosts_total" ]; then
    pass "all ${hosts_total} lab hostnames present → ${server_ip}"
else
    fail "${hosts_found}/${hosts_total} lab hostnames in /etc/hosts — re-run setup-client.sh"
fi

# ── aichat (AI client) config ───────────────────────────────
section "aichat config"
AICHAT_CFG="${HOME}/.config/aichat/config.yaml"
if [ -f "$AICHAT_CFG" ]; then
    pass "aichat config present"
    info "model:    $(grep -E '^model:'  "$AICHAT_CFG" | head -1 | sed 's/^model: *//')"
    info "endpoint: $(grep -E 'api_base:' "$AICHAT_CFG" | head -1 | sed 's/.*api_base: *//')"
else
    fail "aichat config not found at ${AICHAT_CFG}"
fi

# ── Fish shell config ───────────────────────────────────────
section "Fish shell config"
FISH_CFG="${HOME}/.config/fish/config.fish"
if [ -f "$FISH_CFG" ]; then
    if grep -q "starship init fish" "$FISH_CFG"; then
        pass "Starship prompt wired into Fish"
    else
        warn "Starship init missing from Fish config"
    fi
    if grep -q 'alias k=' "$FISH_CFG"; then
        pass "'k' kubectl alias present"
    else
        warn "'k' alias missing from Fish config"
    fi
else
    fail "Fish config not found at ${FISH_CFG}"
fi

# ── Docker → Harbor trust ───────────────────────────────────
section "Docker registry trust (Harbor)"
HARBOR_CA="/etc/docker/certs.d/harbor.${LAB_DOMAIN}/ca.crt"
if [ -f "$HARBOR_CA" ]; then
    pass "Docker trusts harbor.${LAB_DOMAIN} (per-registry CA installed)"
else
    warn "Docker registry CA missing (${HARBOR_CA}) — 'docker push' to Harbor may fail on TLS"
fi

# ── Lab connectivity (HTTPS via the Gateway) ────────────────
# A trusted-cert HTTPS request to each lab host. Any HTTP code
# back means the network path AND the lab CA trust both work;
# the code then says whether that app is actually serving.
# Client-side faults (DNS, untrusted cert) FAIL; server-side
# ones (unreachable, 404) only WARN — they aren't this VM's fault.
section "Lab connectivity (HTTPS via the Gateway)"
check_url() {
    local host="$1"
    local code rc
    code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 12 "https://${host}" 2>/dev/null)"
    rc=$?
    if [ "$rc" -eq 0 ]; then
        case "$code" in
            200|30*) pass "${host} → HTTP ${code}" ;;
            404)     warn "${host} → HTTP 404 (reached the Gateway, but no route — app not deployed)" ;;
            *)       warn "${host} → HTTP ${code} (reached + cert trusted; app may not be serving)" ;;
        esac
    else
        case "$rc" in
            60) fail "${host} → TLS cert NOT trusted (lab CA missing/stale, or server serving a default cert)" ;;
            6)  fail "${host} → DNS not resolving (check /etc/hosts)" ;;
            7)  warn "${host} → connection refused (lab server down, or firewall blocking 443)" ;;
            28) warn "${host} → timed out (lab server unreachable — firewall/NSG blocking 443?)" ;;
            *)  warn "${host} → curl exit ${rc}" ;;
        esac
    fi
}
for h in poll docs ai argocd harbor gitea rancher grafana db mailpit; do
    check_url "${h}.${LAB_DOMAIN}"
done

# ── Kubernetes API access (optional) ────────────────────────
section "Kubernetes API access"
if [ -f "${HOME}/.kube/config" ]; then
    if kubectl cluster-info --request-timeout=8s > /dev/null 2>&1; then
        pass "kubectl reaches the cluster"
    else
        warn "~/.kube/config exists but kubectl can't reach the cluster"
    fi
else
    info "no ~/.kube/config yet — get your kubeconfig from Rancher (expected before that step)"
fi

# ── Summary ─────────────────────────────────────────────────
section "Summary"
echo "  ✅ ${PASS} passed    ⚠️  ${WARN} warning(s)    ❌ ${FAIL} failed"
echo ""
if [ "$FAIL" -gt 0 ]; then
    echo "🛠️  ${FAIL} check(s) failed — see the ❌ lines above."
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo "⚓ Client VM is correctly set up. ${WARN} warning(s) above are"
    echo "   likely server-side (a lab service not yet deployed) — review them."
    exit 0
else
    echo "⚓ Client VM looks shipshape. Fair winds, sailor!"
    exit 0
fi
