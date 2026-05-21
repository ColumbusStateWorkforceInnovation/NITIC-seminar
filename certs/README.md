# ⚓ Admiral Bash's Lab TLS Certificates

**Issuing Authority:** National Information Technology Innovation Center (NITIC)
**Program:** Working Connections — DevOps Intensive
**Fleet:** ITIN Working Connections Fleet
**Valid For:** 20 days (intentionally ephemeral — lab use only)
**Expires:** Jun 10 03:33:31 2026 GMT
**Covers:** `*.nitic2026cbus.voyage` and all lab subdomains

---

## What's in This Directory

| File | Committed to Repo? | Purpose |
|------|--------------------|---------|
| `ca.crt` | ✅ Yes | Students install this to trust the CA |
| `tls.crt` | ✅ Yes | Wildcard public cert (safe to share) |
| `ca.key` | ❌ No (gitignored) | CA private key — kept by instructor |
| `tls.key` | ❌ No (gitignored) | TLS private key — copied to server via scp |

---

## Instructor: Distribute the Key to the Server

The private key is **not** in the repo. Copy it to the server before running the kubectl command:

```bash
# Securely copy the private key to the server
scp certs/tls.key ubuntu@<SERVER_IP>:/tmp/tls.key
scp certs/tls.crt ubuntu@<SERVER_IP>:/tmp/tls.crt

# Then SSH in and create the Kubernetes secret
ssh ubuntu@<SERVER_IP>
kubectl create secret tls wildcard-tls \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  -n admin-tools \
  --dry-run=client -o yaml | kubectl apply -f -

# Clean up the key from /tmp on the server
rm /tmp/tls.key /tmp/tls.crt
```

---

## For Students (Ubuntu 24.04 VM)

Your `setup-client.sh` handles this automatically. If you need to do it manually:

```bash
# Install the CA cert into the OS trust store
sudo cp certs/ca.crt /usr/local/share/ca-certificates/nitic-lab-ca.crt
sudo update-ca-certificates

# Verify it's trusted
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt certs/tls.crt
```

---

## Covered Subdomains

| Subdomain | Service |
|-----------|---------|
| rancher.nitic2026cbus.voyage | Rancher Dashboard |
| argocd.nitic2026cbus.voyage | ArgoCD GitOps UI |
| gitea.nitic2026cbus.voyage | Gitea Git Server |
| harbor.nitic2026cbus.voyage | Harbor Container Registry |
| grafana.nitic2026cbus.voyage | Grafana Dashboards |
| ai.nitic2026cbus.voyage | Ollama/LiteLLM AI Endpoint |
| mailpit.nitic2026cbus.voyage | Mailpit Email Sandbox |
| db.nitic2026cbus.voyage | Adminer Database UI |
| docs.nitic2026cbus.voyage | MkDocs Curriculum |
| poll.nitic2026cbus.voyage | Flash Poll App |

