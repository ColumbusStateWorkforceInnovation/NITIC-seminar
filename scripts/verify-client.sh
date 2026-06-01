#!/bin/bash
# ============================================================
# ⚓ Admiral Bash's Island Adventure — Client VM Self-Check
# ============================================================
#
# PURPOSE:
#   Verifies a student/client VM after setup-client.sh has run:
#   the lab tools, Docker, TLS trust, lab hostname resolution
#   (public DNS in production / /etc/hosts pins in self-hosted mode),
#   the aichat and Fish configs, Harbor registry trust, and HTTPS
#   connectivity to the lab cluster through the Gateway.
#
#   Read-only — installs nothing, needs no sudo. Safe to re-run.
#
# USAGE:
#   bash scripts/verify-client.sh
#
# OPTIONAL ENV:
#   LAB_DOMAIN   Override the lab domain (default: wagbiz.org).
#
# EXIT CODE:
#   0 — every client-side check passed (warnings allowed).
#   1 — at least one client-side check failed.
#   Warnings cover things that aren't the client's fault (a lab
#   service down, a route not deployed) — they don't fail the run.
# ============================================================

LAB_DOMAIN="${LAB_DOMAIN:-wagbiz.org}"

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
check_tool code     --version
check_tool kubectl  version --client
check_tool helm     version --short
check_tool k9s      version
check_tool d2       --version
check_tool aichat   --version
check_tool hail     --help

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

# ── TLS trust ───────────────────────────────────────────────
# The production cluster serves a real Let's Encrypt cert, trusted natively —
# normally there is no lab CA to find, and that is correct. The real proof is
# the HTTPS connectivity check further down. A legacy self-signed CA is only
# present on a no-public-DNS deployment (INSTALL_LAB_CA=1); report it if so.
section "TLS trust"
CA_FILE="/usr/local/share/ca-certificates/nitic-working-connections-ca.crt"
if [ -f "$CA_FILE" ]; then
    ca_exp="$(openssl x509 -in "$CA_FILE" -noout -enddate 2>/dev/null | cut -d= -f2)"
    if openssl x509 -in "$CA_FILE" -noout -checkend 0 > /dev/null 2>&1; then
        info "legacy self-signed lab CA installed (valid until ${ca_exp})"
    else
        warn "legacy self-signed lab CA installed but EXPIRED (${ca_exp})"
    fi
else
    info "no lab CA installed — expected; the cluster uses a real Let's Encrypt cert"
fi

# ── Lab hostname resolution ─────────────────────────────────
# Two valid paths:
#   1) Production (real DNS): lab subdomains resolve via public DNS; /etc/hosts
#      is empty of lab entries and that is correct.
#   2) Self-hosted (k3d-on-laptop / no-DNS): setup-client.sh pinned every
#      subdomain in /etc/hosts at SERVER_IP. We require all 10 to be present.
# We detect the path by looking at /etc/hosts first; if any lab entry is
# present we expect the self-hosted shape; otherwise we verify public DNS.
section "Lab hostname resolution"
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

# Portable DNS lookup: try the tools each platform actually ships.
# - getent (Linux/glibc) — present on Ubuntu (where students will run this).
# - host  (bind9-host)   — present on macOS and most Linux installs.
# - python3              — fallback when neither of the above exists.
# Echoes the resolved IP on success, returns nonzero on failure.
resolve_host() {
    local h="$1"
    if command -v getent > /dev/null 2>&1; then
        getent hosts "$h" 2>/dev/null | awk '{print $1; exit}' | grep -q . && return 0 || true
    fi
    if command -v host > /dev/null 2>&1; then
        host -t A "$h" 2>/dev/null | awk '/has address/ {print $4; exit}' | grep -q . && return 0 || true
    fi
    if command -v python3 > /dev/null 2>&1; then
        python3 -c "import socket,sys
try: print(socket.gethostbyname('$h'))
except Exception: sys.exit(1)" 2>/dev/null && return 0 || true
    fi
    return 1
}

resolve_host_ip() {
    local h="$1"
    if command -v getent > /dev/null 2>&1; then
        local v
        v="$(getent hosts "$h" 2>/dev/null | awk '{print $1; exit}')"
        [ -n "$v" ] && { echo "$v"; return 0; }
    fi
    if command -v host > /dev/null 2>&1; then
        local v
        v="$(host -t A "$h" 2>/dev/null | awk '/has address/ {print $4; exit}')"
        [ -n "$v" ] && { echo "$v"; return 0; }
    fi
    if command -v python3 > /dev/null 2>&1; then
        python3 -c "import socket; print(socket.gethostbyname('$h'))" 2>/dev/null && return 0
    fi
    return 1
}

if [ "$hosts_found" -eq 0 ]; then
    # Production path — confirm public DNS resolves harbor.${LAB_DOMAIN}.
    if resolved="$(resolve_host_ip "harbor.${LAB_DOMAIN}")"; then
        pass "public DNS resolves harbor.${LAB_DOMAIN} → ${resolved} (production mode)"
    else
        fail "harbor.${LAB_DOMAIN} does not resolve and no /etc/hosts pin — DNS down? Or self-host without SERVER_IP set?"
    fi
elif [ "$hosts_found" -eq "$hosts_total" ]; then
    pass "all ${hosts_total} lab hostnames pinned in /etc/hosts → ${server_ip} (self-hosted mode)"
else
    fail "${hosts_found}/${hosts_total} lab hostnames in /etc/hosts — partial pin, re-run setup-client.sh with SERVER_IP set"
fi

# ── aichat (AI client) config ───────────────────────────────
section "aichat config"
AICHAT_CFG="${HOME}/.config/aichat/config.yaml"
if [ -f "$AICHAT_CFG" ]; then
    pass "aichat config present"
    info "model:    $(grep -E '^model:'  "$AICHAT_CFG" | head -1 | sed 's/^model: *//')"
    info "endpoint: $(grep -E 'api_base:' "$AICHAT_CFG" | head -1 | sed 's/.*api_base: *//')"
    # Probe the AI endpoint so a wrong/placeholder key is caught HERE, not later
    # when aichat fails in Lab 00 Part 6. Auth-only check (-k: TLS trust is
    # verified separately above).
    _ai_base="$(grep -E 'api_base:' "$AICHAT_CFG" | head -1 | sed 's/.*api_base: *//' | tr -d ' "')"
    _ai_key="$(grep -E 'api_key:'  "$AICHAT_CFG" | head -1 | sed 's/.*api_key: *//' | tr -d ' "')"
    _ai_code="$(curl -sS -k -o /dev/null -w '%{http_code}' --max-time 10 "${_ai_base%/}/models" -H "Authorization: Bearer ${_ai_key}" 2>/dev/null || echo 000)"
    case "$_ai_code" in
        200)         pass "AI endpoint reachable and key accepted" ;;
        400|401|403) fail "AI key rejected (HTTP ${_ai_code}) — export the AI_API_KEY from the board and re-run setup-client.sh" ;;
        000)         warn "couldn't reach the AI endpoint (cluster may not be reachable from here yet)" ;;
        *)           warn "AI endpoint returned HTTP ${_ai_code}" ;;
    esac
else
    fail "aichat config not found at ${AICHAT_CFG}"
fi

# ── Boatswain persona wiring ────────────────────────────────
# Lab 01 onward depends on `hail` summoning a role backed by ~/lab/AGENTS.md.
# Three things must line up: the working file exists, the role symlink points
# at it, and the wrapper script can be invoked. Each check fails independently
# so we know which piece broke without re-running setup.
section "Boatswain persona (Lab 01+)"
AGENTS_FILE="${HOME}/lab/AGENTS.md"
ROLE_LINK="${HOME}/.config/aichat/roles/boatswain.md"
HAIL_BIN="/usr/local/bin/hail"

if [ -e "$AGENTS_FILE" ]; then
    pass "~/lab/AGENTS.md exists (the Boatswain's rule book)"
else
    fail "~/lab/AGENTS.md missing — re-run setup-client.sh"
fi

if [ -L "$ROLE_LINK" ]; then
    link_target="$(readlink "$ROLE_LINK")"
    if [ "$link_target" = "$AGENTS_FILE" ] || [ "$(cd "$(dirname "$ROLE_LINK")" && readlink -f "$ROLE_LINK" 2>/dev/null)" = "$(readlink -f "$AGENTS_FILE" 2>/dev/null)" ]; then
        pass "boatswain role symlinked → ${link_target}"
    else
        warn "boatswain role symlinked but to an unexpected target: ${link_target}"
    fi
elif [ -f "$ROLE_LINK" ]; then
    warn "boatswain role exists but isn't a symlink — edits to ~/lab/AGENTS.md won't flow through"
else
    fail "boatswain role missing at ${ROLE_LINK} — re-run setup-client.sh"
fi

if [ -x "$HAIL_BIN" ]; then
    pass "/usr/local/bin/hail installed and executable"
else
    fail "/usr/local/bin/hail missing or not executable — re-run setup-client.sh"
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
# With the real Let's Encrypt cert, the Docker daemon trusts harbor.${LAB_DOMAIN}
# via the system trust store — no per-registry cert is needed. A per-registry
# cert is only present on the legacy self-signed path.
section "Docker registry trust (Harbor)"
HARBOR_CA="/etc/docker/certs.d/harbor.${LAB_DOMAIN}/ca.crt"
if [ -f "$HARBOR_CA" ]; then
    info "legacy per-registry CA present for harbor.${LAB_DOMAIN}"
else
    info "no per-registry CA — Docker trusts harbor.${LAB_DOMAIN} via the system store"
fi

# ── Harbor login (Lab 01 'docker push') ─────────────────────
# The #1 silent Lab 01 failure: the VM was never actually logged in to Harbor
# (the docker group wasn't active when setup ran, or the robot token was rotated
# afterward), so `docker push` dies with "unauthorized". Confirm an auth entry
# for harbor.${LAB_DOMAIN} is persisted in the docker config — that's what push
# uses. Warn (not fail): it's normal to be logged out before Lab 01, and there's
# a one-step fix.
DOCKER_CFG="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
HARBOR_CREDS_URL="${HARBOR_CREDS_URL:-https://docs.${LAB_DOMAIN}/creds/harbor-robot.env}"
if [ -f "$DOCKER_CFG" ] && grep -q "harbor.${LAB_DOMAIN}" "$DOCKER_CFG" 2>/dev/null; then
    pass "Docker is logged in to harbor.${LAB_DOMAIN} (Lab 01 'docker push' will work)"
else
    warn "Docker is NOT logged in to harbor.${LAB_DOMAIN} — Lab 01 'docker push' will say 'unauthorized'."
    echo "      Fix it in one step (copy-paste the whole line — works in fish or bash):"
    # bash -c wrapper: the labs run in fish (can't source a KEY=value file, mangles
    # the '$' in the robot username). Creds parsed literally so the '$' survives.
    sed "s|@URL@|${HARBOR_CREDS_URL}|; s|@HOST@|harbor.${LAB_DOMAIN}|" <<'HINT'
        bash -c 'curl -fsSL @URL@ -o /tmp/h.env && u=$(grep "^HARBOR_ROBOT_USER=" /tmp/h.env | cut -d= -f2-) && s=$(grep "^HARBOR_ROBOT_SECRET=" /tmp/h.env | cut -d= -f2-) && printf %s "$s" | docker login @HOST@ -u "$u" --password-stdin'
HINT
fi

# ── Lab connectivity (HTTPS via the Gateway) ────────────────
# A trusted-cert HTTPS request to each lab host. Any HTTP code
# back means the network path AND TLS trust both work;
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
            60) fail "${host} → TLS cert NOT trusted (server may be serving a default/expired cert)" ;;
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
