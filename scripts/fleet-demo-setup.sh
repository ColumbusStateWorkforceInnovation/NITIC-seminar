#!/bin/bash
# ============================================================
# ⚓ Admiral Bash's Island Adventure — Fleet Logistics Demo Setup
# ============================================================
#
# PURPOSE:
#   Pre-flights the 30-min instructor-led 3-tier demo (Day 2).
#   Run-sheet: docs/missions/day-02/demo-fleet-logistics.md
#   Manifests: docs/missions/day-02/fleet-demo/
#
#   It does the two things you can't do dramatically in front of the
#   room without dead air:
#     1. Creates the three fleet-* namespaces (so the live `apply` of the
#        tiers is instant, not waiting on namespace admission).
#     2. Adds the `fleet.<domain>` /etc/hosts line so the browser can
#        resolve the new frontend hostname — the per-subdomain DNS the
#        cluster does NOT auto-create.
#   It also sanity-checks that main-gateway is Programmed before you start.
#   Idempotent — safe to re-run.
#
# USAGE:
#   LAB_DOMAIN=wagbiz.org bash scripts/fleet-demo-setup.sh
#   bash scripts/fleet-demo-setup.sh teardown      # remove everything
#
# RUN IT:
#   A few minutes before the demo. Tear down after with `teardown` (below)
#   or: kubectl delete ns fleet-storehouse fleet-ledger fleet-radar
# ============================================================

set -euo pipefail

LAB_DOMAIN="${LAB_DOMAIN:-wagbiz.org}"
HOSTNAME_FQDN="fleet.${LAB_DOMAIN}"
NAMESPACES=(fleet-storehouse fleet-ledger fleet-radar)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/../docs/missions/day-02/fleet-demo"

# ── teardown subcommand ──────────────────────────────────────
if [[ "${1:-}" == "teardown" ]]; then
  echo "🧹 Tearing down the fleet demo..."
  kubectl delete ns "${NAMESPACES[@]}" --ignore-not-found
  if grep -q " ${HOSTNAME_FQDN}$" /etc/hosts 2>/dev/null; then
    sudo sed -i.bak "/ ${HOSTNAME_FQDN}\$/d" /etc/hosts
    echo "   ✅ Removed ${HOSTNAME_FQDN} from /etc/hosts"
  fi
  echo "✅ Done."
  exit 0
fi

echo "⚓ Pre-flighting the Fleet Logistics demo (domain: ${LAB_DOMAIN})..."

# 1. Namespaces.
kubectl apply -f "${MANIFEST_DIR}/namespaces.yaml"

# 2. /etc/hosts — borrow the cluster IP from a hostname that already resolves.
SERVER_IP="$(getent hosts "gitea.${LAB_DOMAIN}" | awk '{print $1}' || true)"
if [[ -z "${SERVER_IP}" ]]; then
  echo "   ⚠️  Could not resolve gitea.${LAB_DOMAIN} to borrow the cluster IP."
  echo "      Add the /etc/hosts line yourself:  <cluster-ip>  ${HOSTNAME_FQDN}"
elif grep -q " ${HOSTNAME_FQDN}$" /etc/hosts 2>/dev/null; then
  echo "   ↪ /etc/hosts already has ${HOSTNAME_FQDN}."
else
  echo "${SERVER_IP}  ${HOSTNAME_FQDN}" | sudo tee -a /etc/hosts >/dev/null
  echo "   ✅ Added '${SERVER_IP}  ${HOSTNAME_FQDN}' to /etc/hosts"
fi

# 3. Gateway sanity check.
if kubectl get gateway main-gateway -n admin-tools \
     -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null \
     | grep -q True; then
  echo "   ⚓ main-gateway is Programmed — the front door is open."
else
  echo "   ⚠️  main-gateway is not Programmed. Check 'kubectl describe gateway main-gateway -n admin-tools' before you start."
fi

cat <<DEMO

═════════════════════════════════════════════════════════════
🎬 Fleet Logistics — your live apply order

   M=docs/missions/day-02/fleet-demo

   # Tier 1 — Storehouse (cache)
   kubectl apply -f \$M/cache.yaml
   kubectl get endpoints cache -n fleet-storehouse

   # Tier 2 — Ledger (backend) + the silent-break beat (see backend.yaml header)
   kubectl apply -f \$M/backend.yaml

   # Tier 3 — Radar (frontend + HTTPRoute)
   kubectl apply -f \$M/frontend.yaml
   kubectl describe httproute fleet-radar -n fleet-radar   # Accepted / ResolvedRefs
   # browser → https://${HOSTNAME_FQDN}

   # Finale — the blockade, then recover
   kubectl apply -f \$M/blockade.yaml
   kubectl apply -f \$M/allow-rules.yaml

Tear down after the demo:
   bash scripts/fleet-demo-setup.sh teardown
═════════════════════════════════════════════════════════════

DEMO
