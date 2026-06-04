#!/usr/bin/env bash
# Pre-flight for Day 3 Lab 02 "The Automated Shipyard" (the afternoon ArgoCD lab).
# Read-only — it changes nothing. Run it before class from the repo root:
#
#     ./scripts/preflight-argocd-lab.sh
#
# It honors the same LOCAL/REMOTE switch as the justfile (reads lab.env):
#   - REMOTE: SERVER_IP set in lab.env  -> SSHes to azureuser@$SERVER_IP
#   - LOCAL:  .just-target = 1 or LOCAL=1 -> runs kubectl locally
# Override the wrapper explicitly with:  SSH='ssh -i key user@host' ./scripts/preflight-argocd-lab.sh
set -uo pipefail
cd "$(dirname "$0")/.."

# ── Resolve the kubectl wrapper (mirror justfile) ───────────────────────────
[ -f lab.env ] && set -a && . ./lab.env && set +a
SERVER_IP="${SERVER_IP:-}"
SERVER_USER="${SERVER_USER:-azureuser}"
SERVER_SSH_KEY="${SERVER_SSH_KEY:-$HOME/.ssh/id_rsa}"
PIN="$(tr -d '[:space:]' < .just-target 2>/dev/null || true)"
LOCAL="${LOCAL:-${PIN:-$([ -z "$SERVER_IP" ] && echo 1 || echo 0)}}"
if [ -z "${SSH:-}" ]; then
  if [ "$LOCAL" = "1" ]; then SSH="bash -c"
  else SSH="ssh -i $SERVER_SSH_KEY $SERVER_USER@$SERVER_IP"; fi
fi
k() { $SSH "kubectl $*"; }

FAIL=0; WARN=0
ok()   { printf '   ✅ %s\n' "$1"; }
bad()  { printf '   ❌ %s\n' "$1"; FAIL=$((FAIL+1)); }
warn() { printf '   ⚠️  %s\n' "$1"; WARN=$((WARN+1)); }

echo "🏴‍☠️  Lab 02 pre-flight  (wrapper: $SSH)"
echo

# ── 1. ArgoCD admin password (read it out to the room) ──────────────────────
echo "1) ArgoCD admin password (shared 'admin' login for the lab)"
PW="$(k "-n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'" 2>/dev/null | base64 -d 2>/dev/null || true)"
if [ -n "$PW" ]; then
  printf '   ✅ admin password:  \033[1m%s\033[0m\n' "$PW"
else
  bad "Could not read argocd-initial-admin-secret. Is ArgoCD up? (kubectl -n argocd get pods)"
fi
echo

# ── 2. grant-raider applied (Step 4 the Raid) ───────────────────────────────
echo "2) Raid rights (just grant-raider) — needed for Lab 02 Step 4"
NSES="$(k "get ns -o name" 2>/dev/null | sed 's#namespace/##' | grep -E '^student-' || true)"
if [ -z "$NSES" ]; then
  warn "No student-* namespaces found yet (provision first)."
else
  MISSING=0; TOTAL=0
  while read -r NS; do
    [ -z "$NS" ] && continue
    TOTAL=$((TOTAL+1))
    k "get rolebinding student-raider -n $NS" >/dev/null 2>&1 || MISSING=$((MISSING+1))
  done <<< "$NSES"
  if [ "$MISSING" -eq 0 ]; then ok "student-raider RoleBinding present in all $TOTAL student namespaces"
  else bad "student-raider missing in $MISSING/$TOTAL namespaces — run: just grant-raider"; fi
  # Functional check: can an authenticated student delete a deployment in someone else's ns?
  VICTIM="$(echo "$NSES" | head -1)"
  CANI="$(k "auth can-i delete deployment -n $VICTIM --as=preflight-probe --as-group=system:authenticated" 2>/dev/null || true)"
  [ "$CANI" = "yes" ] && ok "authenticated user CAN delete deployments in $VICTIM (raid works)" \
                       || warn "auth can-i delete deployment in $VICTIM => '${CANI:-no}' (expected yes)"
fi
echo

# ── 3. Self-Heal on for every student Application ───────────────────────────
echo "3) Self-Heal enabled on student Applications (so sabotage reverts)"
APPS_JSON="$(k "-n argocd get applications.argoproj.io -o json" 2>/dev/null || true)"
if [ -z "$APPS_JSON" ] || ! echo "$APPS_JSON" | grep -q '"items"'; then
  warn "No Applications yet (students create them in the lab) — re-check once a few are made."
else
  NOHEAL="$(echo "$APPS_JSON" | jq -r '.items[] | select((.spec.syncPolicy.automated.selfHeal // false) != true) | .metadata.name' 2>/dev/null || true)"
  if [ -z "$NOHEAL" ]; then ok "every existing student Application has selfHeal: true"
  else warn "selfHeal NOT set on: $(echo "$NOHEAL" | paste -sd', ' -)  (the Raid won't revert for these)"; fi
fi
echo

# ── 4. Clear-decks: student namespaces have CPU headroom ────────────────────
echo "4) CPU budget free (just clear-decks ran — else Lab 01 pods sit Pending)"
QJSON="$(k "get resourcequota -A -o json" 2>/dev/null || true)"
if [ -n "$QJSON" ] && echo "$QJSON" | grep -q student-; then
  TIGHT="$(echo "$QJSON" | jq -r '
    .items[] | select(.metadata.namespace|startswith("student-"))
    | . as $q | ($q.status.used["requests.cpu"] // "0") as $u | ($q.status.hard["requests.cpu"] // "0") as $h
    | select($u != "0" and $u != null) | "\($q.metadata.namespace): \($u)/\($h) cpu used"' 2>/dev/null || true)"
  if [ -z "$TIGHT" ]; then ok "student namespaces are empty/low — full quota available for Lab 01"
  else
    warn "student namespaces still carry workloads (Day 2 leftovers?). Consider: just clear-decks"
    echo "$TIGHT" | sed 's/^/        /'
  fi
else
  warn "Could not read ResourceQuotas."
fi
echo

# ── 5. Gitea + ArgoCD reachable to students ─────────────────────────────────
echo "5) Core services up"
for d in "gitea-http.admin-tools" "argocd"; do :; done
GP="$(k "-n admin-tools get pods -l app.kubernetes.io/name=gitea -o jsonpath='{.items[*].status.phase}'" 2>/dev/null || true)"
[ -n "$GP" ] && echo "$GP" | grep -qv '[^ ]*Pending' && ok "Gitea pods: $GP" || warn "Gitea pod phase: '${GP:-unknown}' (students push here)"
AP="$(k "-n argocd get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.phase}'" 2>/dev/null || true)"
[ -n "$AP" ] && ok "ArgoCD server: $AP" || warn "ArgoCD server phase: '${AP:-unknown}'"
echo

# ── Summary ─────────────────────────────────────────────────────────────────
if [ "$FAIL" -eq 0 ]; then
  echo "✅ Pre-flight clean${WARN:+ ($WARN warning(s) — review above)}. You're ready for the afternoon lab."
else
  echo "❌ $FAIL blocking issue(s) and $WARN warning(s). Fix the ❌ items before class."
  exit 1
fi
