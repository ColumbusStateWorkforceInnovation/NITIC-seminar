#!/usr/bin/env bash
# grade-cluster-recovery.sh — Day 4 capstone grading gate.
#
# Verifies that an alliance's 3-tier app has survived the Pirate Strikes
# chaos attack and is serving traffic reliably. This is the 40-point
# "cluster restored" gate of the Salvage Report rubric.
#
# Pass criteria (all three must hold):
#   1. Every Pod in the target namespace is Ready.
#   2. A 60-second curl loop against the frontend Service returns HTTP 2xx
#      ≥ 95% of the time (allowing for some packet loss from active chaos).
#   3. The alliance's ArgoCD Application reports Synced + Healthy.
#
# Usage:
#   ./scripts/grade-cluster-recovery.sh <namespace> [frontend-service-name]
#
# Defaults (match the Day-3 island-stack chart naming, "<crew>-<tier>"):
#   - for namespace "student-<crew>", the frontend Service defaults to
#     "<crew>-frontend" and the ArgoCD Application to "<crew>-stack"
#   - override the service via the 2nd arg, the app via GRADE_APP_NAME=<name>
#
# Exit codes:
#   0  — pass (all three gates green)
#   1  — fail (any gate red)
#   2  — usage / configuration error

set -uo pipefail

NS="${1:-}"
# Day-3 island-stack names every object "<crew>-<tier>" where <crew> is the
# namespace minus the "student-" prefix. Derive the frontend Service and the
# ArgoCD Application from that convention; both stay overridable.
CREW="${NS#student-}"
FRONTEND_SVC="${2:-${CREW}-frontend}"
APP_NAME="${GRADE_APP_NAME:-${CREW}-stack}"
DURATION="${GRADE_DURATION:-60}"     # seconds of curl-loop probing
MIN_SUCCESS_PCT="${GRADE_MIN_SUCCESS_PCT:-95}"

if [[ -z "$NS" ]]; then
  echo "usage: $0 <namespace> [frontend-service-name]" >&2
  echo "       GRADE_APP_NAME=<argo-app> (defaults to namespace)" >&2
  exit 2
fi

# ── Helpers ──────────────────────────────────────────────────────
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
hr()    { printf -- '─%.0s' {1..60}; printf '\n'; }

PASS=true
RESULTS=()

# ── Gate 1: every Pod in the namespace is Ready ──────────────────
hr
echo "Gate 1 — Pod readiness in namespace '$NS'"
hr

# kubectl get pods, parse Ready column ("1/1", "2/2", "0/1", etc.)
NOT_READY=$(kubectl get pods -n "$NS" \
  -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.status.containerStatuses[*].ready}{"\n"}{end}' \
  2>/dev/null | awk -F'|' '$2 ~ /false/ {print $1}')

POD_COUNT=$(kubectl get pods -n "$NS" --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [[ "$POD_COUNT" -eq 0 ]]; then
  red "✗ No pods found in namespace $NS"
  RESULTS+=("Gate 1 (pod readiness): FAIL — no pods in namespace")
  PASS=false
elif [[ -n "$NOT_READY" ]]; then
  red "✗ Some pods are NOT Ready:"
  echo "$NOT_READY" | sed 's/^/    /'
  RESULTS+=("Gate 1 (pod readiness): FAIL — pods not ready: $(echo "$NOT_READY" | tr '\n' ' ')")
  PASS=false
else
  green "✓ All $POD_COUNT pods Ready in $NS"
  RESULTS+=("Gate 1 (pod readiness): PASS — $POD_COUNT/$POD_COUNT ready")
fi

# ── Gate 2: ≥95% HTTP 2xx over 60 seconds ────────────────────────
hr
echo "Gate 2 — Frontend reliability ($DURATION s curl loop, ≥${MIN_SUCCESS_PCT}% success)"
hr

# Resolve the Service ClusterIP from inside the cluster context. We use
# kubectl run --rm to spin up an ephemeral curl pod in the same namespace so
# we don't depend on having the Service exposed externally.
PROBE_OUTPUT=$(kubectl run grading-probe \
  --rm --restart=Never --quiet -i \
  --image=curlimages/curl:8.10.1 \
  -n "$NS" \
  --timeout=$((DURATION + 30))s \
  --command -- sh -c "
    SUCCESS=0
    FAIL=0
    END=\$(( \$(date +%s) + $DURATION ))
    while [ \$(date +%s) -lt \$END ]; do
      code=\$(curl -s -o /dev/null -m 2 -w '%{http_code}' http://$FRONTEND_SVC.$NS.svc.cluster.local/ 2>/dev/null)
      if [ \"\$code\" -ge 200 ] && [ \"\$code\" -lt 300 ] 2>/dev/null; then
        SUCCESS=\$((SUCCESS + 1))
      else
        FAIL=\$((FAIL + 1))
      fi
      sleep 1
    done
    echo \"SUCCESS=\$SUCCESS FAIL=\$FAIL\"
  " 2>&1)

SUCCESS=$(echo "$PROBE_OUTPUT" | grep -oE 'SUCCESS=[0-9]+' | tail -1 | cut -d= -f2)
FAIL=$(echo "$PROBE_OUTPUT"    | grep -oE 'FAIL=[0-9]+'    | tail -1 | cut -d= -f2)
SUCCESS=${SUCCESS:-0}
FAIL=${FAIL:-0}
TOTAL=$((SUCCESS + FAIL))

if [[ "$TOTAL" -eq 0 ]]; then
  red "✗ Curl probe produced no results — pod failed to schedule, or Service $FRONTEND_SVC.$NS doesn't exist"
  echo "  Last 10 lines of probe output:"
  echo "$PROBE_OUTPUT" | tail -10 | sed 's/^/    /'
  RESULTS+=("Gate 2 (reliability): FAIL — probe pod produced no results")
  PASS=false
else
  PCT=$(( SUCCESS * 100 / TOTAL ))
  if [[ "$PCT" -ge "$MIN_SUCCESS_PCT" ]]; then
    green "✓ ${SUCCESS}/${TOTAL} requests succeeded (${PCT}%)"
    RESULTS+=("Gate 2 (reliability): PASS — ${SUCCESS}/${TOTAL} (${PCT}%)")
  else
    red "✗ ${SUCCESS}/${TOTAL} requests succeeded (${PCT}%, need ${MIN_SUCCESS_PCT}%)"
    RESULTS+=("Gate 2 (reliability): FAIL — ${SUCCESS}/${TOTAL} (${PCT}%, need ${MIN_SUCCESS_PCT}%)")
    PASS=false
  fi
fi

# ── Gate 3: ArgoCD Application is Synced + Healthy ───────────────
hr
echo "Gate 3 — ArgoCD Application '$APP_NAME' is Synced + Healthy"
hr

if ! kubectl get application "$APP_NAME" -n argocd >/dev/null 2>&1; then
  yellow "⚠ ArgoCD Application '$APP_NAME' not found in 'argocd' namespace"
  echo "  Set GRADE_APP_NAME if your team's Application has a different name."
  RESULTS+=("Gate 3 (ArgoCD): FAIL — Application $APP_NAME not found")
  PASS=false
else
  SYNC=$(kubectl get application "$APP_NAME" -n argocd -o jsonpath='{.status.sync.status}')
  HEALTH=$(kubectl get application "$APP_NAME" -n argocd -o jsonpath='{.status.health.status}')
  # A pod-kill firing during the grade window briefly flips the app to
  # Progressing. That's the chaos, not a real failure — give it up to 30s to
  # settle back to Healthy before judging (avoids a spurious re-run).
  if [[ "$SYNC" == "Synced" && "$HEALTH" == "Progressing" ]]; then
    yellow "⏳ Application Progressing (chaos in flight) — waiting up to 30s to stabilize..."
    for _ in $(seq 1 6); do
      sleep 5
      HEALTH=$(kubectl get application "$APP_NAME" -n argocd -o jsonpath='{.status.health.status}')
      [[ "$HEALTH" == "Healthy" ]] && break
    done
  fi
  if [[ "$SYNC" == "Synced" && "$HEALTH" == "Healthy" ]]; then
    green "✓ Application $APP_NAME — Sync=$SYNC, Health=$HEALTH"
    RESULTS+=("Gate 3 (ArgoCD): PASS — Sync=$SYNC, Health=$HEALTH")
  else
    red "✗ Application $APP_NAME — Sync=$SYNC, Health=$HEALTH"
    RESULTS+=("Gate 3 (ArgoCD): FAIL — Sync=$SYNC, Health=$HEALTH")
    PASS=false
  fi
fi

# ── Summary (paste this into the Salvage Report § 4) ─────────────
hr
echo "SUMMARY (paste into Salvage Report § 4)"
hr
echo "Namespace:    $NS"
echo "Probed:       http://$FRONTEND_SVC.$NS.svc.cluster.local/"
echo "Duration:     ${DURATION}s, threshold ${MIN_SUCCESS_PCT}%"
echo "Argo app:     $APP_NAME"
echo "Timestamp:    $(date -u +%Y-%m-%dT%H:%M:%SZ)"
for r in "${RESULTS[@]}"; do
  echo "  - $r"
done

if $PASS; then
  green "RESULT: PASS"
  exit 0
else
  red "RESULT: FAIL"
  exit 1
fi
