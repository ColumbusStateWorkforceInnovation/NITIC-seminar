#!/bin/bash
# [Boatswain] Admiral Bash's Island Adventure
# ============================================================
# generate-lab-cert.sh — Lab TLS Certificate Generator
# ============================================================
#
# PURPOSE:
#   Generates a self-signed Certificate Authority and a wildcard
#   TLS certificate for the lab domain (*.wagbiz.org).
#
#   The CA cert is distributed to student VMs so their browsers
#   and CLI tools trust the cluster's HTTPS endpoints without
#   warnings. The TLS cert/key are loaded into Kubernetes as a
#   Secret and referenced by the Gateway listener.
#
#   Cert lifetime: 20 days (intentionally ephemeral — tied to
#   the duration of the Working Connections seminar.)
#
# USAGE (run once, from the project root):
#   bash scripts/generate-lab-cert.sh
#
# OUTPUT:
#   certs/ca.crt         — CA cert  (commit to repo, distribute to students)
#   certs/ca.key         — CA key   (keep secure, do NOT share)
#   certs/tls.crt        — Wildcard cert (commit to repo)
#   certs/tls.key        — Wildcard key  (gitignored — scp'd to the server)
#   certs/README.md      — Instructions for students + cluster setup
#
# NEXT STEP (run on the server):
#   kubectl create secret tls wildcard-tls \
#     --cert=certs/tls.crt \
#     --key=certs/tls.key \
#     -n admin-tools
# ============================================================

set -euo pipefail

# ── Config ──────────────────────────────────────────────────
# All values read from environment variables with defaults.
# Override via lab.env (loaded by the justfile) or export before running.
#
# Changing LAB_DOMAIN requires updating:
#   k8s/core-tools/gateway-routes.yaml  (all hostnames)
#   k8s/core-tools/argocd-values.yaml   (global.domain)
#   k8s/core-tools/gitea-values.yaml    (ingress.hosts)
#   k8s/core-tools/harbor-values.yaml   (expose.ingress.hosts)
#   scripts/setup-client.sh             (/etc/hosts entries)
DOMAIN="${LAB_DOMAIN:-wagbiz.org}"
DAYS="${CERT_DAYS:-20}"
ORG_NAME="${ORG_NAME:-National Information Technology Innovation Center}"
ORG_UNIT="${ORG_UNIT:-ITIN Working Connections Fleet}"
LOCALITY="${ORG_LOCALITY:-Columbus}"
STATE="${ORG_STATE:-Ohio}"
COUNTRY="${ORG_COUNTRY:-US}"
OUT_DIR="certs"

WILDCARD="*.${DOMAIN}"

# Certificate Subject Fields
# O  = Organization (NITIC — National Information Technology Innovation Center)
# OU = Organizational Unit (the seminar / fleet)
# CN = Common Name (wildcard domain)
# L  = Locality (nautical flavor)
# ST = State
# C  = Country
CA_SUBJ="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORG_NAME}/OU=${ORG_UNIT}/CN=Admiral Bash Lab CA"
TLS_SUBJ="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORG_NAME}/OU=Admiral Bash Island Adventure/CN=${WILDCARD}"

# ── Safety Check ─────────────────────────────────────────────
if ! command -v openssl &> /dev/null; then
  echo "❌ openssl is required but not found. Install it and try again."
  exit 1
fi

mkdir -p "${OUT_DIR}"

# Guard: warn if certs already exist
if [[ -f "${OUT_DIR}/ca.crt" ]]; then
  echo ""
  echo "⚠️  Existing certs found in ${OUT_DIR}/."
  read -r -p "   Overwrite and regenerate? (y/N): " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted. Existing certs preserved."; exit 0; }
fi

echo ""
echo "⚓ Admiral Bash's Island Adventure — Lab Certificate Authority"
echo "   Issuing certificates under the flag of:"
echo "   National Information Technology Innovation Center (NITIC)"
echo "   Working Connections DevOps Intensive — 20-Day Lab Charter"
echo ""

# ── Step 1: Generate the CA ──────────────────────────────────
echo "🏴‍☠️  Step 1/4: Generating Certificate Authority (CA)..."

# CA private key (4096-bit RSA — strong enough to impress, fast enough for a laptop)
openssl genrsa -out "${OUT_DIR}/ca.key" 4096 2>/dev/null

# Self-signed CA certificate
openssl req -new -x509 \
  -days "${DAYS}" \
  -key "${OUT_DIR}/ca.key" \
  -out "${OUT_DIR}/ca.crt" \
  -subj "${CA_SUBJ}" \
  2>/dev/null

echo "   ✅ CA generated: ${OUT_DIR}/ca.crt"

# ── Step 2: Generate the Wildcard TLS Key & CSR ─────────────
echo "🗺️   Step 2/4: Generating wildcard TLS key and CSR..."

openssl genrsa -out "${OUT_DIR}/tls.key" 2048 2>/dev/null

openssl req -new \
  -key "${OUT_DIR}/tls.key" \
  -out "${OUT_DIR}/tls.csr" \
  -subj "${TLS_SUBJ}" \
  2>/dev/null

echo "   ✅ TLS key + CSR generated."

# ── Step 3: Sign the Cert with the CA ───────────────────────
echo "🖊️   Step 3/4: Signing wildcard certificate with CA..."

# Build SAN (Subject Alternative Names) extension config
# Covers both *.wagbiz.org and wagbiz.org itself
cat > "${OUT_DIR}/san.cnf" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${WILDCARD}
DNS.2 = ${DOMAIN}
DNS.3 = rancher.${DOMAIN}
DNS.4 = argocd.${DOMAIN}
DNS.5 = gitea.${DOMAIN}
DNS.6 = harbor.${DOMAIN}
DNS.7 = grafana.${DOMAIN}
DNS.8 = ai.${DOMAIN}
DNS.9 = mailpit.${DOMAIN}
DNS.10 = docs.${DOMAIN}
DNS.11 = poll.${DOMAIN}
DNS.12 = db.${DOMAIN}
EOF

openssl x509 -req \
  -days "${DAYS}" \
  -in "${OUT_DIR}/tls.csr" \
  -CA "${OUT_DIR}/ca.crt" \
  -CAkey "${OUT_DIR}/ca.key" \
  -CAcreateserial \
  -out "${OUT_DIR}/tls.crt" \
  -extensions v3_req \
  -extfile "${OUT_DIR}/san.cnf" \
  2>/dev/null

# Clean up temporary files
rm -f "${OUT_DIR}/tls.csr" "${OUT_DIR}/san.cnf" "${OUT_DIR}/ca.srl"

echo "   ✅ Wildcard cert signed: ${OUT_DIR}/tls.crt"

# ── Step 4: Generate README and verify ──────────────────────
echo "📋  Step 4/4: Generating README and verifying cert..."

# Quick verification
ACTUAL_CN=$(openssl x509 -in "${OUT_DIR}/tls.crt" -noout -subject | sed 's/.*CN *= *//')
EXPIRY=$(openssl x509 -in "${OUT_DIR}/tls.crt" -noout -enddate | cut -d= -f2)
ISSUER=$(openssl x509 -in "${OUT_DIR}/tls.crt" -noout -issuer | sed 's/.*O *= *//' | cut -d',' -f1 | sed 's/\/.*//')

cat > "${OUT_DIR}/README.md" <<README
# ⚓ Admiral Bash's Lab TLS Certificates

**Issuing Authority:** National Information Technology Innovation Center (NITIC)
**Program:** Working Connections — DevOps Intensive
**Fleet:** ITIN Working Connections Fleet
**Valid For:** ${DAYS} days (intentionally ephemeral — lab use only)
**Expires:** ${EXPIRY}
**Covers:** \`*.${DOMAIN}\` and all lab subdomains

---

## What's in This Directory

| File | Committed to Repo? | Purpose |
|------|--------------------|---------|
| \`ca.crt\` | ✅ Yes | Students install this to trust the CA |
| \`tls.crt\` | ✅ Yes | Wildcard public cert (safe to share) |
| \`ca.key\` | ❌ No (gitignored) | CA private key — kept by instructor |
| \`tls.key\` | ❌ No (gitignored) | TLS private key — copied to server via scp |

---

## Instructor: Distribute the Key to the Server

The private key is **not** in the repo. Copy it to the server before running the kubectl command:

\`\`\`bash
# Securely copy the private key to the server
scp certs/tls.key ubuntu@<SERVER_IP>:/tmp/tls.key
scp certs/tls.crt ubuntu@<SERVER_IP>:/tmp/tls.crt

# Then SSH in and create the Kubernetes secret
ssh ubuntu@<SERVER_IP>
kubectl create secret tls wildcard-tls \\
  --cert=/tmp/tls.crt \\
  --key=/tmp/tls.key \\
  -n admin-tools \\
  --dry-run=client -o yaml | kubectl apply -f -

# Clean up the key from /tmp on the server
rm /tmp/tls.key /tmp/tls.crt
\`\`\`

---

## For Students (Ubuntu 24.04 VM)

Your \`setup-client.sh\` handles this automatically. If you need to do it manually:

\`\`\`bash
# Install the CA cert into the OS trust store
sudo cp certs/ca.crt /usr/local/share/ca-certificates/nitic-lab-ca.crt
sudo update-ca-certificates

# Verify it's trusted
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt certs/tls.crt
\`\`\`

---

## Covered Subdomains

| Subdomain | Service |
|-----------|---------|
| rancher.${DOMAIN} | Rancher Dashboard |
| argocd.${DOMAIN} | ArgoCD GitOps UI |
| gitea.${DOMAIN} | Gitea Git Server |
| harbor.${DOMAIN} | Harbor Container Registry |
| grafana.${DOMAIN} | Grafana Dashboards |
| ai.${DOMAIN} | Ollama/LiteLLM AI Endpoint |
| mailpit.${DOMAIN} | Mailpit Email Sandbox |
| db.${DOMAIN} | Adminer Database UI |
| docs.${DOMAIN} | MkDocs Curriculum |
| poll.${DOMAIN} | Flash Poll App |

README

echo "   ✅ README written: ${OUT_DIR}/README.md"

# ── Summary ─────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo "🏝️  Lab Certificate Authority is COMMISSIONED"
echo ""
echo "   Issuer : National Information Technology Innovation Center"
echo "   Fleet  : ITIN Working Connections Fleet"
echo "   CN     : ${ACTUAL_CN}"
echo "   Expiry : ${EXPIRY}"
echo ""
echo "   Files in ${OUT_DIR}/:"
echo "   ├── ca.crt    ← Commit to repo ✅  (students need this)"
echo "   ├── tls.crt   ← Commit to repo ✅  (public cert, safe)"
echo "   ├── ca.key    ← DO NOT commit ❌  (gitignored — keep locally)"
echo "   ├── tls.key   ← DO NOT commit ❌  (gitignored — scp to server)"
echo "   └── README.md ← Instructions"
echo ""
echo "   NEXT — copy key to server:"
echo "   scp certs/tls.key ubuntu@<SERVER_IP>:/tmp/tls.key"
echo "   scp certs/tls.crt ubuntu@<SERVER_IP>:/tmp/tls.crt"
echo ""
echo "   Then on the server:"
echo "   kubectl create secret tls wildcard-tls \\"
echo "     --cert=/tmp/tls.crt --key=/tmp/tls.key \\"
echo "     -n admin-tools --dry-run=client -o yaml | kubectl apply -f -"
echo "════════════════════════════════════════════════════════"
echo ""
