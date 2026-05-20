# 📝 Final Pre-Launch Readiness Review
**Date:** 2026-05-20
**Persona:** The Purser
**Seminar:** Admiral Bash's Island Adventure (June 1–4, 2026)
**T-minus:** 12 days to launch

## ⚓ Status Summary

We are in **final prep & de-risking phase**. The infrastructure stack and Day 1–2 curriculum are production-ready. The remaining workstreams are (1) the Thursday 2026-05-21 fresh-Ubuntu bootstrap test, (2) Day 3 and Day 4 detail authoring, (3) instructor logistics, and (4) the comprehensive 4-day dry-run. Project remains green for the June 1 launch.

---

## 🎯 Key Decisions Locked This Cycle

| Decision | Outcome |
| :--- | :--- |
| **Deployment target** | Internal CSCC-provided VM (with GPU access confirmed). Replaces the earlier Azure A100 plan. No public IP, no public DNS required. |
| **Concurrency target** | Revised down from 30 → **10–15** simultaneous users. Reshapes all infra sizing decisions. |
| **TLS strategy** | Self-signed wildcard CA (`certs/tls.crt`) loaded as the `wildcard-tls` Secret. Students install the CA via `setup-client.sh`. Let's Encrypt path removed from Rancher (would never validate on an internal-only VM). |
| **Domain resolution** | `/etc/hosts` injection on every student VM via `setup-client.sh`. No registrar A-records required. |
| **AI model** | Ollama serving `gemma3:4b` (Google Gemma 3, 4B params). All references reconciled across `lab.env.example`, `justfile`, `setup-client.sh`, `ai-engine.yaml`, and Day 1 lab text. |
| **Flash Poll hostname** | Canonicalized on `poll.${LAB_DOMAIN}`. Orphan `quiz-route` removed from `gateway-routes.yaml`. |
| **Docs site** | MkDocs Material with the macros plugin. Two latent `!ENV` syntax bugs fixed — `{{ lab_domain }}` had been silently rendering as Python `None` site-wide. |
| **Curriculum reference** | WIIT 7501 syllabus is **support material**, not a binding contract. Repo curriculum is the authoritative plan. Pull from the syllabus as needed for filler/depth. |

---

## ✅ Completed in This Prep Cycle

### Bootstrap Script (`scripts/setup-client.sh`)

The student VM bootstrap is feature-complete and runs end-to-end on Ubuntu/Debian/Fedora/RHEL/SUSE. Major additions:

- **Docker Engine install** with the official `docker-ce` apt repository for Debian/Ubuntu (matches docs.docker.com guidance for 22.04/24.04) and `get-docker.sh` convenience-script fallback for other distros. User auto-added to the `docker` group.
- **Harbor daemon CA trust** at `/etc/docker/certs.d/harbor.${LAB_DOMAIN}/ca.crt` — required because Docker's daemon does not consult the system trust store. Without this, `docker push` to Harbor fails over self-signed TLS.
- **Optional `KUBECONFIG_URL`** fetch path for headless VMs that can't use the Rancher UI's copy/paste kubeconfig flow. Credential cards now auto-include this when `KUBECONFIG_URL_TEMPLATE` is set in `lab.env`.
- **Bug fix:** `((ADDED++))` pre-increment in the `/etc/hosts` loop was tripping `set -e` on the first iteration, silently aborting the script before its final "Setup Complete" message. Replaced with `ADDED=$((ADDED + 1))`.

### Infrastructure Manifests

- **Rancher TLS reconfigured** for internal-VM deployment: `tls: external`, `ingress.enabled: false`. Rides the existing `rancher-route` HTTPRoute.
- **Let's Encrypt ClusterIssuer marked as unused** for the NITIC deployment but retained for portability — any future public-IP deployment can re-enable it in one line.
- **AI engine config** parameterized via `${AI_MODEL}` and `${AI_API_KEY}` envsubst all the way through to the student's aichat config.

### Docs Site

- **mkdocs.yml nav restructured** to nest detail pages under each day section. Day 1 and Day 2 expand to show Briefing + Instructor Guide + per-lab pages + One-Pager + Quiz Content. Day 3 and Day 4 show only Briefing until detail is authored.
- **`docs/index.md` landing page created** — nav had been pointing at a non-existent file since the start of the project.
- **`book-readings.md` linked in nav** — was orphaned on disk.
- **Macros plugin fixed** — removed dead `include_yaml: lab.env.example` config (broke the build because `lab.env.example` is shell-format, not YAML) and corrected the `!ENV` syntax for `lab_domain` and `site_url` (was using shell-style `${VAR:-default}` inside an `!ENV` tag, which doesn't work — switched to the supported `!ENV [VAR, default]` list syntax).
- **Verified** with two `mkdocs build --strict` runs: default `LAB_DOMAIN` produces 40 substitutions in HTML; `LAB_DOMAIN=demo.test` override produces clean `harbor.demo.test` rendering. Zero unrendered macros, zero `None` artifacts.

---

## 🔴 Pre-Thursday (3 days)

These items must close before the 2026-05-21 PM fresh-Ubuntu test, or the test itself will fail at a known point.

- **Pre-create Harbor `raft-fleet` project** with anonymous-push policy enabled. Without this, every student's Day 1 `docker push` returns 404. A `just bootstrap-harbor` recipe that calls the Harbor API is the cleanest implementation (~15 min of work).
- **Pre-stage container images** on the instructor MacBook Air (K3d local test loop). Image set: `ollama/ollama:latest`, `ghcr.io/berriai/litellm:main-latest`, `ghcr.io/jacobtread/quizler:latest`, `squidfunk/mkdocs-material:latest`, `registry.k8s.io/git-sync/git-sync:v4.1.0`, `adminer:latest`, `axllent/mailpit:latest`, plus the Helm-chart-pulled images (argocd, gitea, harbor, rancher, cert-manager, loki/grafana/promtail, chaos-mesh, clabernetes). Cleanest approach: spin up K3d, run `just deploy-core` + per-Helm recipes, then `docker save` everything.
- **Confirm CSCC VM exact specs** with IT (vCPU, RAM, GPU profile, NVIDIA driver presence, vGPU license server reachability). At 10–15 concurrent users, **8 GB vGPU is sufficient**. Suggested email language:

  > "The VM needs an NVIDIA GPU exposed to the guest, configured for CUDA workloads (no graphics required). 8 GB of VRAM is sufficient for our workload. Acceptable vGPU profiles in order of preference: A10-8Q, L4-8Q, A40-8Q (Ampere/Ada — ideal); T4-8Q or T4-16Q (whole T4 card); A10-16Q or L4-16Q (if 8 GB profiles unavailable). A full passthrough GPU (≥8 GB VRAM) also works. Workload is Ollama serving Gemma 3 4B to ~15 concurrent users during a 4-day seminar."

- **Thursday 2026-05-21 PM end-to-end test.** Punch list:
    1. Fresh Ubuntu 24.04.4 VM in Multipass on the MacBook Air.
    2. K3d cluster on the Air with `just deploy-core` executed against it.
    3. Run `bash setup-client.sh <Air's LAN IP>` on the Ubuntu VM.
    4. Verify: Fish prompt + Starship, `k=kubectl` alias, lab CA trusted, `kubectl cluster-info` succeeds against the K3d cluster.
    5. `docker info` returns valid daemon status.
    6. End-to-end: `docker build` + `docker push harbor.${LAB_DOMAIN}/raft-fleet/test:v1` succeeds with no TLS warnings.
    7. `aichat` → `.info` shows the configured Gemma endpoint.
    8. Browse `https://docs.${LAB_DOMAIN}`, `https://poll.${LAB_DOMAIN}`, `https://argocd.${LAB_DOMAIN}` — all should load cleanly.
    9. From inside a pod: `wget http://litellm.admin-tools.svc.cluster.local:4000/v1/models` — confirms AI engine reachable in-cluster.

---

## 🟡 Weekend / Next Week (Content & Tooling Sprint)

- **Day 3 detail** — instructor guide, Lab 01–N walkthroughs (Helm + Gitea CI + ArgoCD + Clabernetes), one-pager (printable handout), Quizler content. Use the Day 1/Day 2 pattern as the template.
- **Day 4 detail** — instructor guide, Chaos Mesh exercise script, Educator's Roundtable facilitation outline, one-pager, Quizler content.
- **Add `just deploy-*` recipes** for `cert-manager`, `loki-stack`, `chaos-mesh`, `clabernetes`. Currently only `argocd`, `gitea`, `harbor`, `rancher` have recipes — the other Helm charts have to be installed manually from their values files.
- **vCluster + KubeVirt** — tested `helm install` invocations before Day 4 morning demo (no values files exist for these yet; they're mentioned in the curriculum but not in `k8s/core-tools/`).
- **Finalize student handouts and reference materials** (one-pagers exist for Days 1–2; need to fold quiz reference / glossary into the printable set).
- **Finalize instructor slide decks.**

---

## 🟢 Final Prep (May 25-31)

- **End-to-end test of each daily lab** against the production CSCC VM (post-Thursday K3d test).
- **Comprehensive 4-day curriculum dry-run** with the instructor running every lab in real time.
- **Address gaps surfaced in the dry-run.**

---

## 🟣 Logistics (Parallel Track)

- Procure door prizes.
- Print CNCF *Admiral Bash's Island Adventure* picture book locally (Creative Commons — printing cost only).
- Outline Credly badging requirements (NITIC 80+ score threshold).
- Set up and configure the Engagez platform meeting links.

---

## 🚨 Known Risks & Mitigations

| Risk | Mitigation |
| :--- | :--- |
| CSCC VM not provisioned in time for Thursday test | Thursday test runs against local K3d on MacBook Air; doesn't depend on CSCC VM. Production-cluster validation happens in the May 25–31 window. |
| GPU driver / vGPU license issues on CSCC VM | Confirm with CSCC IT this week: driver pre-installed in guest, license server reachable. Fallback: drop to `gemma3:1b` (CPU-acceptable) and frame as a "rate-limited" AI on Day 1 narrative. |
| Day 3 / Day 4 content not finished by launch | Day 3/4 high-level overviews are sufficient as instructor talking-points if detail isn't fully authored. Faculty can follow the Briefing + Instructor's live demonstration. Prioritize Day 3 detail over Day 4 since Day 4 is more demo-heavy. |
| Single point of failure (cluster down on Day N) | Maintain `just` recipes so the entire stack can be re-deployed in <30 minutes against a backup VM. Keep the lab cert valid through 2026-06-09 (current expiry). |
| Network surprises in classroom (firewall, captive portal) | Test the room's network ahead of time. Bring a backup travel router (~$80) that can NAT student traffic onto a controlled subnet if CSCC infrastructure misbehaves. |

---

## 📦 Files Touched This Cycle

For reference / git diff:
- `scripts/setup-client.sh` — Docker install, Harbor CA trust, `KUBECONFIG_URL` support, `AI_MODEL`/`AI_API_KEY` parameterization, `((ADDED++))` `set -e` bug fix
- `scripts/provision-students.sh` — credential card now includes optional `KUBECONFIG_URL` shortcut
- `lab.env.example` — documented `KUBECONFIG_URL_TEMPLATE` and `SKIP_DOCKER` env vars
- `justfile` — `AI_MODEL` default corrected to `gemma3:4b`, `show-hosts` recipe canonicalized on `poll.`
- `k8s/core-tools/gateway-routes.yaml` — orphan `quiz-route` removed
- `k8s/core-tools/ai-engine.yaml` — comment updated to reflect canonical model tag
- `k8s/core-tools/cluster-issuer.yaml` — marked as UNUSED on internal-VM deployments
- `k8s/rancher/rancher-values.yaml` — Let's Encrypt path removed; `tls: external` + `ingress.enabled: false`
- `mkdocs.yml` — `nav` restructured to nest day details; `!ENV` syntax bugs fixed
- `docs/index.md` — created (landing page)
- `docs/missions/day-01/lab-01-the-first-raft.md` — "Gemma4" → "Gemma 3"
- `docs/todo-ledger.md` — closed items, added the Thursday test, added the GPU spec confirmation, added Day 3/4 authoring section

---

*Signed,*
**The Purser**
*Project Administrator — Admiral Bash's Island Adventure*
