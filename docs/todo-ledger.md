# 📋 Purser's Todo Ledger

**Goal:** Pre-launch readiness for "Admiral Bash's Island Adventure" DevOps Intensive by **2026-05-31** (seminar runs June 1–4).

## 📊 Status Summary

- **Current Phase:** Final prep & de-risking. Bootstrap script (Thursday fresh-Ubuntu test), Day 3/4 content, and Logistics are the three remaining workstreams.

## 🗓️ Methodology

This ledger tracks major milestones across four primary domains to ensure overall readiness by the target date.

---

# Notes from call 4/22

- One-pager for each day idea
  - topics for day, and small info sheet
  - back for notes
  - fun pirate drawings all-around

- glossary and back references to topics, the book, and github repo

---

### 📚 Curriculum & Content

- [x] Establish high-level narrative and 4-day course outline.
- [x] Draft initial daily mission concepts.
- [x] Align daily objectives with core WIIT syllabus topics.
- [x] Deploy an in-cluster documentation platform (e.g., MkDocs or Educates.dev) to serve mission docs dynamically.
- [ ] Draft quiz content/questions for each day to load into the Flash Poll app.
- [ ] Develop and finalize student handouts and reference materials.
- [ ] Finalize instructor slide decks.

### 💻 Lab Infrastructure

- [x] Confirm the lab environment architecture: **One Giant Shared k3d Cluster**.
- [x] Wildcard DNS A-Record — **not required**. Deployment target is an internal CSCC VM (10.x.y.z, no public reachability). Students resolve lab subdomains via `/etc/hosts` injection in `setup-client.sh`. (Re-open this if CSCC IT later offers internal DNS or a public IP.)
- [x] Reconfigure Rancher TLS — removed Let's Encrypt ingress source (would never validate on internal-only cluster). Rancher now runs `tls: external` with `ingress.enabled: false`; TLS terminates at the Gateway via the existing `rancher-route` HTTPRoute using the wildcard-tls secret.
- [x] Develop backend manifests and Helms charts to bootstrap the core cluster capabilities:
  - [x] Internal Registry (Harbor)
  - [x] GitOps Engine (ArgoCD) & Version Control (Gitea)
  - [x] Networking Topologies (Clabernetes & Containerlab)
  - [ ] Instructor Demonstration Tools (vCluster & KubeVirt - Single Instance) — *values files missing; needs a tested `helm install` invocation before Day 4 demo*
  - [x] Incident Engine (Chaos Mesh)
  - [x] Local AI Inference Engine (Ollama hosting Gemma 3 4B; tag `gemma3:4b`)
- [x] Write `setup-client.sh` bootstrap script. Provisions Fish + Starship, k=kubectl alias, Docker (with Harbor CA trust), kubectl, helm, k9s, d2, aichat (pointed at the cluster's Gemma endpoint), the lab CA, and optional `KUBECONFIG_URL` kubeconfig fetch.
- [x] Finalize student workstation network access requirements with CSCC IT (Standard SSH/CLI access to the shared cluster; NO Kasm/Guacamole required).
- [ ] Perform end-to-end testing of daily lab exercises in the finalized environment.
- [X] **Thursday 2026-05-21 PM:** Fresh-Ubuntu 24.04.4 install — run `setup-client.sh` end-to-end and walk a real Day 1 docker push.
- [ ] Add justfile recipes for cert-manager, loki-stack, chaos-mesh, clabernetes (currently no `deploy-*` for these — only argocd/gitea/harbor/rancher are scripted).
- [ ] Pre-create Harbor `raft-fleet` project with anonymous-push policy (Day 1 lab depends on it).
- [x] Reconcile `quiz` vs `poll` subdomain — canonicalized on `poll.${LAB_DOMAIN}` across `setup-client.sh`, `justfile show-hosts`, and `gateway-routes.yaml` (orphan `quiz-route` removed).
- [x] Reconcile AI model name on `gemma3:4b` (Ollama). setup-client.sh and justfile default now parameterized via `AI_MODEL` env var; `ai-engine.yaml` comment and Day 1 lab text updated. (Dated stakeholder updates left as historical snapshots.)
- [ ] Pre-stage container images on instructor MacBook Air (K3d local test loop). See review notes for image list.

### 📚 Curriculum Authoring — Day 3 & 4 Detail

- [ ] Day 3 instructor guide, lab walkthroughs (Helm + Gitea CI + ArgoCD + Clabernetes), one-pager, and quizler content. *(Day 1 and Day 2 detail exists; Day 3 currently only has the high-level overview.)*
- [ ] Day 4 instructor guide, Chaos Mesh exercise script, Educator's Roundtable facilitation outline, one-pager, and quizler content.
- [x] Add the day-01 and day-02 subfolders to `mkdocs.yml` `nav:` (nested under each day section; Day 3/4 entries ready to expand once detail is authored). Also created the missing `docs/index.md` landing page and fixed two latent `!ENV` syntax bugs that were rendering `{{ lab_domain }}` as Python `None` in the live site.

### 🎁 Logistics & Platform

- [X] Procure door prizes.
- [X] Look into printing the CNCF books locally (e.g., *Admiral Bash*). They are under Creative Commons, so the only cost is printing.
- [X] Outline badging requirements (Credly).
- [X] Set up and configure the Engagez platform.

### 👩‍🏫 Instructor Prep

- [ ] Conduct comprehensive dry-run of the 4-day curriculum.
- [ ] Address any gaps identified during the dry-run.
