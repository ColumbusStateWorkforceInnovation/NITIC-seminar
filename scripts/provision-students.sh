#!/bin/bash
# [Boatswain] Admiral Bash's Island Adventure
# ============================================================
# provision-students.sh — Idempotent Student Provisioner
# ============================================================
#
# PURPOSE:
#   Reads a students.csv file and provisions each student in
#   Rancher via the REST API. Idempotent — safe to re-run.
#
# USAGE:
#   export RANCHER_URL="https://rancher.your-domain.com"
#   export RANCHER_TOKEN="token-xxxxx:yyyyy"
#   ./scripts/provision-students.sh --roster scripts/students.csv
#
# FLAGS:
#   --roster FILE     Path to students CSV (default: scripts/students.csv)
#   --student NAME    Provision only a single student by username
#   --reset NAME      Delete and re-create a single student's namespace
#   --output-dir DIR  Where to write credential cards (default: /tmp/creds)
#   --dry-run         Print what would happen without making API calls
#
# CSV FORMAT (no header row):
#   username,display_name,email
#   tanaka,Hiroshi Tanaka,h.tanaka@nitic.ac.jp
# ============================================================

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────
ROSTER="scripts/students.csv"
SINGLE_STUDENT=""
RESET_STUDENT=""
OUTPUT_DIR="/tmp/creds"
DRY_RUN=false
PASSWORD_PREFIX="AdmiralBash"

# ── Argument Parsing ─────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --roster)     ROSTER="$2";         shift 2 ;;
    --student)    SINGLE_STUDENT="$2"; shift 2 ;;
    --reset)      RESET_STUDENT="$2";  shift 2 ;;
    --output-dir) OUTPUT_DIR="$2";     shift 2 ;;
    --dry-run)    DRY_RUN=true;        shift   ;;
    *) echo "❌ Unknown flag: $1"; exit 1 ;;
  esac
done

# ── Prerequisite Checks ──────────────────────────────────────
if [[ -z "${RANCHER_URL:-}" ]]; then
  echo "❌ RANCHER_URL is not set. Export it before running this script."
  echo "   export RANCHER_URL='https://rancher.your-domain.com'"
  exit 1
fi

if [[ -z "${RANCHER_TOKEN:-}" ]]; then
  echo "❌ RANCHER_TOKEN is not set. Export it before running this script."
  echo "   export RANCHER_TOKEN='token-xxxxx:yyyyy'"
  exit 1
fi

if ! command -v curl &> /dev/null; then
  echo "❌ curl is required but not installed."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "❌ jq is required but not installed. (brew install jq)"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ── Helper: Rancher API call ─────────────────────────────────
# Captures the HTTP status separately from the body so auth/HTTP
# failures surface a clear message instead of a cryptic curl exit
# code. (Note: `curl -f` over HTTP/2 reports exit 56 — not 22 — on
# any >=400 status, and `-s` hides the body, so the old `-sf` form
# died here with no explanation when a token was rejected.)
rancher_api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local url="${RANCHER_URL}/v3${path}"
  local body http_code

  # --http1.1 keeps curl's error reporting sane; we read the status
  # ourselves rather than relying on -f.
  if [[ -n "$data" ]]; then
    body=$(curl -s --http1.1 -w $'\n%{http_code}' -X "$method" \
      -H "Authorization: Bearer ${RANCHER_TOKEN}" \
      -H "Content-Type: application/json" \
      "$url" -d "$data")
  else
    body=$(curl -s --http1.1 -w $'\n%{http_code}' -X "$method" \
      -H "Authorization: Bearer ${RANCHER_TOKEN}" \
      "$url")
  fi

  http_code="${body##*$'\n'}"   # last line = status code
  body="${body%$'\n'*}"          # everything before it = response body

  if [[ ! "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    echo "   ❌ Rancher API ${method} ${path} → HTTP ${http_code:-no-response}" >&2
    case "$http_code" in
      401|403) echo "      Token rejected. Check RANCHER_TOKEN is a valid, unexpired API key." >&2 ;;
      000|"")  echo "      No HTTP response — check RANCHER_URL (${RANCHER_URL}) and connectivity." >&2 ;;
    esac
    [[ -n "$body" ]] && echo "      Response: ${body}" >&2
    return 1
  fi

  printf '%s' "$body"
}

# ── Helper: Get local cluster ID ────────────────────────────
get_cluster_id() {
  rancher_api GET "/clusters?name=local" | jq -r '.data[0].id'
}

# ── Helper: Generate a password ─────────────────────────────
generate_password() {
  local username="$1"
  echo "${PASSWORD_PREFIX}-${username}"
}

# ── Helper: Provision one student ───────────────────────────
provision_student() {
  local username="$1"
  local display_name="$2"
  local email="$3"
  local rancher_username="sailor-${username}"
  local namespace="student-${username}"
  local password
  password=$(generate_password "$username")

  echo ""
  echo "⚓ Provisioning: $rancher_username ($display_name)"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "   [DRY RUN] Would create user '$rancher_username', project 'crew-$username', namespace '$namespace'"
    return
  fi

  # 1. Create or verify user exists
  local existing_user
  existing_user=$(rancher_api GET "/users?username=${rancher_username}" | jq -r '.data[0].id // empty')
  
  if [[ -n "$existing_user" ]]; then
    echo "   👤 User already exists (ID: $existing_user) — skipping creation."
    USER_ID="$existing_user"
  else
    echo "   👤 Creating user..."
    USER_ID=$(rancher_api POST "/users" "{
      \"username\": \"${rancher_username}\",
      \"name\": \"${display_name}\",
      \"password\": \"${password}\",
      \"mustChangePassword\": false,
      \"enabled\": true
    }" | jq -r '.id')
    echo "   ✅ User created (ID: $USER_ID)"
  fi

  # 2. Assign 'user' global role so they can log in
  local existing_role_binding
  existing_role_binding=$(rancher_api GET "/globalrolebindings?userId=${USER_ID}&globalRoleId=user" | jq -r '.data[0].id // empty')

  if [[ -z "$existing_role_binding" ]]; then
    rancher_api POST "/globalrolebindings" "{
      \"globalRoleId\": \"user\",
      \"userId\": \"${USER_ID}\"
    }" > /dev/null
    echo "   ✅ Global 'user' role assigned."
  else
    echo "   🔒 Global role already bound — skipping."
  fi

  # 3. Get local cluster ID
  local CLUSTER_ID
  CLUSTER_ID=$(get_cluster_id)
  if [[ -z "$CLUSTER_ID" || "$CLUSTER_ID" == "null" ]]; then
    echo "   ❌ Could not find 'local' cluster in Rancher. Is the cluster registered?"
    exit 1
  fi

  # 4. Create Project (idempotent check by name)
  local existing_project
  existing_project=$(rancher_api GET "/projects?name=crew-${username}&clusterId=${CLUSTER_ID}" | jq -r '.data[0].id // empty')

  if [[ -n "$existing_project" ]]; then
    echo "   🏴 Project 'crew-$username' already exists (ID: $existing_project) — skipping."
    PROJECT_ID="$existing_project"
  else
    echo "   🏴 Creating project 'crew-$username'..."
    PROJECT_ID=$(rancher_api POST "/projects" "{
      \"name\": \"crew-${username}\",
      \"clusterId\": \"${CLUSTER_ID}\",
      \"description\": \"⚓ ${display_name}'s crew quarters.\",
      \"resourceQuota\": {
        \"limit\": {
          \"limitsCpu\": \"2000m\",
          \"limitsMemory\": \"2048Mi\"
        },
        \"usedLimit\": {}
      },
      \"namespaceDefaultResourceQuota\": {
        \"limit\": {
          \"limitsCpu\": \"500m\",
          \"limitsMemory\": \"512Mi\"
        }
      },
      \"containerDefaultResourceLimit\": {
        \"limitsCpu\": \"100m\",
        \"limitsMemory\": \"96Mi\",
        \"requestsCpu\": \"25m\",
        \"requestsMemory\": \"64Mi\"
      }
    }" | jq -r '.id')
    # containerDefaultResourceLimit makes Rancher create a per-namespace
    # LimitRange that injects default limits/requests into containers that omit
    # them. Without it, the namespaceDefaultResourceQuota above (which caps
    # limits.cpu/limits.memory) REJECTS any limitless pod — including the bare
    # Deployment students generate in Day 2 Lab 02. The failure is silent:
    # `kubectl apply` succeeds but 0 pods ever start (error buried in
    # ReplicaSet events). Keep the defaults * max replicas under the quota:
    # 100m/96Mi * 4 (3 replicas + rolling-update surge) = 400m/384Mi < 500m/512Mi.
    echo "   ✅ Project created (ID: $PROJECT_ID)"
  fi

  # 5. Bind user to project as project-member
  local existing_binding
  existing_binding=$(rancher_api GET "/projectroletemplatebindings?projectId=${PROJECT_ID}&userId=${USER_ID}" | jq -r '.data[0].id // empty')

  if [[ -z "$existing_binding" ]]; then
    rancher_api POST "/projectroletemplatebindings" "{
      \"projectId\": \"${PROJECT_ID}\",
      \"roleTemplateId\": \"project-member\",
      \"userId\": \"${USER_ID}\"
    }" > /dev/null
    echo "   ✅ User bound to project as 'project-member'."
  else
    echo "   🔗 Role binding already exists — skipping."
  fi

  # 6. Create the student's namespace and bind it to their Rancher project.
  # The `field.cattle.io/projectId` annotation is how Rancher associates a
  # namespace with a project — without it, the project-member role binding
  # above doesn't reach into the namespace and the student gets 'Forbidden'
  # on `kubectl get pods`. Idempotent.
  # The annotation value is the fully-qualified project ref `<clusterId>:<projectId>`;
  # Rancher's /v3/projects POST returns just the short form in `.id`, so we
  # prepend the cluster ID. We handle the (rare) case where PROJECT_ID was
  # already returned fully-qualified.
  local ns_project_ref
  if [[ "$PROJECT_ID" == *":"* ]]; then
    ns_project_ref="$PROJECT_ID"
  else
    ns_project_ref="${CLUSTER_ID}:${PROJECT_ID}"
  fi
  if kubectl get namespace "$namespace" > /dev/null 2>&1; then
    echo "   📦 Namespace '${namespace}' already exists — skipping create."
  else
    kubectl create namespace "$namespace" > /dev/null
    echo "   📦 Namespace '${namespace}' created."
  fi
  kubectl annotate namespace "$namespace" \
    "field.cattle.io/projectId=${ns_project_ref}" \
    --overwrite > /dev/null
  echo "   ✅ Namespace bound to project ${ns_project_ref}."

  # 7. Write credential card
  local cred_file="${OUTPUT_DIR}/credentials-${username}.txt"
  local kubeconfig_hint=""
  if [[ -n "${KUBECONFIG_URL_TEMPLATE:-}" ]]; then
    local resolved_url="${KUBECONFIG_URL_TEMPLATE//__USERNAME__/${username}}"
    kubeconfig_hint=$(cat <<EOF

  HEADLESS VM SHORTCUT (no browser needed):
    export STUDENT='${username}'
    export KUBECONFIG_URL='${resolved_url}'
    bash setup-client.sh \$SERVER_IP
  (setup-client.sh fetches your kubeconfig and reprints this card on your VM.)
EOF
)
  fi

  cat > "$cred_file" <<EOF
╔══════════════════════════════════════════╗
║   ⚓ ADMIRAL BASH'S ISLAND ADVENTURE    ║
║         CREW CREDENTIALS CARD           ║
╚══════════════════════════════════════════╝

  Welcome aboard, ${display_name}!

  🌐 Rancher UI:  ${RANCHER_URL}
  👤 Username:    ${rancher_username}
  🔑 Password:    ${password}
  📦 Namespace:   ${namespace}

  STEP 1: Browse to the Rancher URL above.
  STEP 2: Log in with your username & password.
  STEP 3: Click your profile icon (top right).
  STEP 4: Click "Copy KubeConfig to Clipboard".
  STEP 5: Paste into ~/.kube/config

  Then run:
    kubectl get ns
    kubectl get pods -n ${namespace}
${kubeconfig_hint}

  You are ON THE ISLAND. Good luck, sailor! 🏝️
EOF
  echo "   🎟️  Credential card written: $cred_file"
}

# ── Reset mode ───────────────────────────────────────────────
if [[ -n "$RESET_STUDENT" ]]; then
  echo "🔄 RESET MODE: Nuking namespace for student-${RESET_STUDENT}..."
  kubectl delete namespace "student-${RESET_STUDENT}" --ignore-not-found=true
  echo "✅ Namespace deleted. Re-running provision to recreate..."
  SINGLE_STUDENT="$RESET_STUDENT"
fi

# ── Main Provisioning Loop ───────────────────────────────────
if [[ -n "$SINGLE_STUDENT" ]]; then
  # Single student mode — find their row in the CSV
  if ! grep -q "^${SINGLE_STUDENT}," "$ROSTER"; then
    echo "❌ Student '${SINGLE_STUDENT}' not found in roster: $ROSTER"
    exit 1
  fi
  line=$(grep "^${SINGLE_STUDENT}," "$ROSTER")
  IFS=',' read -r username display_name email <<< "$line"
  provision_student "$username" "$display_name" "$email"
else
  # Batch mode — process every row in the CSV
  echo "🏴‍☠️  Admiral Bash's Crew Provisioner — Batch Mode"
  echo "   Roster: $ROSTER"
  echo "   Output: $OUTPUT_DIR"
  echo ""
  
  while IFS=',' read -r username display_name email; do
    # Skip empty lines or comment lines
    [[ -z "$username" || "$username" == \#* ]] && continue
    provision_student "$username" "$display_name" "$email"
  done < "$ROSTER"
fi

echo ""
echo "════════════════════════════════════════════"
echo "✅ All hands accounted for. Crew is aboard!"
echo "   Credential cards are in: $OUTPUT_DIR"
echo "════════════════════════════════════════════"
