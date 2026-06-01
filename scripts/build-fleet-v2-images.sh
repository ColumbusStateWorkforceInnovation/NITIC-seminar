#!/usr/bin/env bash
# build-fleet-v2-images.sh
#
# Pre-flight for the Day 2 morning Kustomize demo.
#
# Lists every student's :v1 raft image in the Harbor `raft-fleet` project,
# rebuilds each as a thin v2 layer (FROM <student>:v1 + injected banner),
# and pushes back as :v2. The Day 2 apply loop then bumps every student's
# raft Pod from v1 to v2 in-place using `kustomize edit set image`.
#
# Requires:
#   - docker (logged in to Harbor — `harbor-robot.env` in repo root handles
#     the credentials via setup-client.sh; this script honours the same env
#     vars if you run it elsewhere)
#   - curl + jq for the Harbor API listing
#
# Usage:
#   ./scripts/build-fleet-v2-images.sh                # discover from Harbor
#   ./scripts/build-fleet-v2-images.sh alice blackbeard ...  # explicit list
#
# Safe to re-run — each iteration is idempotent.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAB_ENV="${LAB_ENV:-$REPO_ROOT/lab.env}"
HARBOR_ENV="${HARBOR_ENV:-$REPO_ROOT/harbor-robot.env}"

# Load LAB_DOMAIN and Harbor credentials.
if [[ -f "$LAB_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$LAB_ENV"
fi
if [[ -f "$HARBOR_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$HARBOR_ENV"
fi

LAB_DOMAIN="${LAB_DOMAIN:-wagbiz.org}"
HARBOR_HOST="harbor.${LAB_DOMAIN}"
HARBOR_PROJECT="${HARBOR_PROJECT:-raft-fleet}"
HARBOR_USER="${HARBOR_ROBOT_USER:-}"
HARBOR_PASS="${HARBOR_ROBOT_SECRET:-}"

if [[ -z "$HARBOR_USER" || -z "$HARBOR_PASS" ]]; then
  echo "✗ Harbor credentials missing. Source $HARBOR_ENV or export HARBOR_ROBOT_USER/HARBOR_ROBOT_SECRET." >&2
  exit 1
fi

discover_students() {
  # Harbor API: list repositories in the raft-fleet project, strip prefix.
  curl -sS --fail \
    -u "${HARBOR_USER}:${HARBOR_PASS}" \
    "https://${HARBOR_HOST}/api/v2.0/projects/${HARBOR_PROJECT}/repositories?page_size=100" \
    | jq -r '.[].name' \
    | sed "s|^${HARBOR_PROJECT}/||"
}

if [[ $# -gt 0 ]]; then
  STUDENTS=("$@")
else
  mapfile -t STUDENTS < <(discover_students)
fi

if [[ ${#STUDENTS[@]} -eq 0 ]]; then
  echo "✗ No students discovered in ${HARBOR_HOST}/${HARBOR_PROJECT}. Did Day 1 pushes happen?" >&2
  exit 1
fi

echo "Building v2 raft images for ${#STUDENTS[@]} students..."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The v2 layer: append a banner overlay so it's visible the second the
# new image lands in the Pod. Works against any v1 built FROM nginx:alpine
# with content at /usr/share/nginx/html/.
cat > "${WORK}/v2-banner.html" <<'HTML'
<div id="kustomize-v2-banner" style="position:fixed;top:0;left:0;right:0;background:#ffd400;color:#111;font-family:system-ui,sans-serif;font-weight:600;text-align:center;padding:10px 14px;z-index:9999;box-shadow:0 2px 6px rgba(0,0,0,.25)">
  ⚓ v2 ROLLOUT — Kustomize did this to your raft with one file.
</div>
HTML

cat > "${WORK}/Dockerfile.v2" <<DOCKERFILE
ARG V1_IMAGE
FROM \${V1_IMAGE}
COPY v2-banner.html /usr/share/nginx/html/v2-banner.html
RUN if [ -f /usr/share/nginx/html/index.html ]; then \
      sed -i 's|<body[^>]*>|&<script>fetch("v2-banner.html").then(r=>r.text()).then(t=>document.body.insertAdjacentHTML("afterbegin",t))</script>|' /usr/share/nginx/html/index.html ; \
    fi
DOCKERFILE

for student in "${STUDENTS[@]}"; do
  v1="${HARBOR_HOST}/${HARBOR_PROJECT}/${student}:v1"
  v2="${HARBOR_HOST}/${HARBOR_PROJECT}/${student}:v2"

  echo "  → ${student}: building ${v2} from ${v1}"
  docker pull "$v1" >/dev/null
  docker build \
    --build-arg "V1_IMAGE=${v1}" \
    -t "$v2" \
    -f "${WORK}/Dockerfile.v2" \
    "${WORK}" >/dev/null
  docker push "$v2" >/dev/null
done

echo
echo "✓ Pushed ${#STUDENTS[@]} v2 images to ${HARBOR_HOST}/${HARBOR_PROJECT}."
echo "  Next: run the apply loop from docs/missions/day-02/kustomize-demo/README.md"
echo "  (or live at 09:11 with a student's k9s on the projector)."
