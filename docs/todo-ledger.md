# 📋 Purser's Todo Ledger

**Goal:** Pre-launch readiness for "Admiral Bash's Island Adventure" DevOps Intensive by **2026-05-31** (seminar runs June 1–4).

## 📊 Status Summary

- **Current Phase (2026-05-25):** T-minus 6 days. Day 1–4 curriculum, all 7 slide decks, and the core infra (k3s + Gateway API + Let's Encrypt + Harbor + Gitea + ArgoCD + Rancher + Dex + Ollama/LiteLLM + GPU plugin) are authored and scripted. Remaining workstreams: (1) AI / aichat / AGENTS.md end-to-end testing on the Horizon Ubuntu VM, (2) chaos-mesh + clabernetes + vCluster + KubeVirt deploy recipes, (3) full lab dry-run against the production GPU VM (`uss-nitic` / 20.80.3.162), (4) commit & push the ~40 working-tree changes.

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
- [x] Draft quiz content/questions for each day to load into the Flash Poll app. *(All four days have `quiz-content.quizler`; Day 2 also has `environment-tooling.quizler`, Day 3 also has `class-architecture.quizler`.)*
- [x] Develop and finalize student handouts and reference materials. *(One-pagers exist for all four days under `docs/missions/day-0N/one-pager.md`.)*
- [x] Finalize instructor slide decks. *(7 decks across Days 1–4 in `slides/`, 412–604 lines each, built to HTML + PDF in `slides/build/`.)*

### 💻 Lab Infrastructure

- [x] Confirm the lab environment architecture: **One Giant Shared k3d Cluster**.
- [x] ~~Wildcard DNS A-Record — not required (internal CSCC VM)~~ **Superseded 2026-05-21:** lab moved to a public-IP Azure GPU VM (`uss-nitic` / 20.80.3.162 in North Central US) on the public domain `wagbiz.org`. Real Let's Encrypt wildcard TLS via cert-manager + Cloudflare DNS-01. Students still hit `/etc/hosts` only as a fallback; primary resolution is real DNS.
- [x] Reconfigure Rancher TLS — Rancher now runs `tls: external` with `ingress.enabled: false`; TLS terminates at the Gateway via the existing `rancher-route` HTTPRoute using the Let's Encrypt wildcard-tls secret.
- [x] Develop backend manifests and Helms charts to bootstrap the core cluster capabilities:
  - [x] Internal Registry (Harbor)
  - [x] GitOps Engine (ArgoCD) & Version Control (Gitea)
  - [x] Networking Topologies (Clabernetes & Containerlab)
  - [ ] Instructor Demonstration Tools (vCluster & KubeVirt - Single Instance) — *values files missing; needs a tested `helm install` invocation before Day 4 demo*
  - [x] Incident Engine (Chaos Mesh)
  - [x] Local AI Inference Engine (Ollama hosting Gemma 3 4B; tag `gemma3:4b`)
- [x] Write `setup-client.sh` bootstrap script. Provisions Fish + Starship, k=kubectl alias, Docker (with Harbor CA trust), kubectl, helm, k9s, d2, aichat (pointed at the cluster's Gemma endpoint), the lab CA, and optional `KUBECONFIG_URL` kubeconfig fetch.
- [x] Finalize student workstation network access requirements with CSCC IT (Standard SSH/CLI access to the shared cluster; NO Kasm/Guacamole required).
- [ ] Perform end-to-end testing of daily lab exercises against the production GPU VM (`uss-nitic` / 20.80.3.162). The 2026-05-21 fresh-Ubuntu test ran against local k3d on the MacBook Air; the GPU VM was redeployed 2026-05-24 and has not been exercised end-to-end since.
- [X] **Thursday 2026-05-21 PM:** Fresh-Ubuntu 24.04.4 install — ran `setup-client.sh` end-to-end and walked a real Day 1 docker push (local k3d on the MacBook Air).
- [x] Add justfile recipes for cert-manager and loki-stack — both done (`deploy-cert-manager`, `deploy-letsencrypt`, `deploy-loki`).
- [ ] **(Post-June-1) Migrate off the deprecated `loki-stack` Helm chart.** `grafana/loki-stack` is deprecated (`WARNING: This chart is deprecated` banner) and unmaintained; effective **2026-03-16** even the active `loki` chart forks to `grafana-community/helm-charts`. It still installs and runs fine, so this is **deferred until after the June 1–4 seminar** — it's a cosmetic warning, not a class-day risk. No drop-in successor exists: `loki-stack` bundles Loki + Promtail + Grafana + an auto-wired datasource, whereas the modern `grafana/loki` chart is **Loki-only**. Migration plan when picked up:
  - Split the one chart into three: **`grafana/loki`** (set `deploymentMode: Monolithic`, `singleBinary.replicas: 1`, `loki.commonConfig.replication_factor: 1`, `storage.type: filesystem` + `schemaConfig` tsdb/v13 from 2024-04-01, and **disable the memcached chunks/results caches** — they default to ~9 Gi memory requests and will wedge k3d), **`grafana/grafana`** (port the entire current `grafana:` block — SSO `auth.generic_oauth`, SMTP→Mailpit, `root_url`, adminPassword from lab.env), and a log collector (**Promtail is also deprecated → Grafana Alloy `grafana/alloy`**, or keep `grafana/promtail` as the low-effort path).
  - Re-wire the Loki **datasource manually** in the Grafana chart (`loki-stack` auto-wired it; the split charts don't).
  - Update `justfile:497` `deploy-loki` → three `helm upgrade --install` calls.
  - Update `k8s/core-tools/gateway-routes.yaml:99` backend `loki-stack-grafana` → `grafana` (new Grafana chart's service name).
  - Sweep docs for the old service/Grafana references: `docs/missions/day-03/sso-walkthrough.md`, `docs/missions/day-03/instructor-guide.md`, `docs/index.md`.
  - Researched 2026-05-30 against grafana.com install-monolithic docs; full minimal values captured in the migration discussion.
- [ ] Add justfile recipes for **chaos-mesh** and **clabernetes** — values files exist in `k8s/core-tools/` but no `deploy-*` recipe. Day 4 instructor playbook installs Chaos Mesh during the 10:30 break (needs a recipe to fit the window); Day 3 Lab 03 needs Clabernetes (currently called out as instructor-installed prereq).
- [ ] **vCluster + KubeVirt** — no values files in `k8s/core-tools/` and no recipes; both featured in Day 4 morning lecture demos. Decide: real demo (author values + recipe + rehearse), screen-recorded demo, or cut. If keeping live: pre-pull images, rehearse against the GPU VM.
- [ ] **Pre-pull `ghcr.io/nokia/srlinux:latest` (~1.5 GB)** to every node before Day 3 — Lab 03's first deploy is slow on a cold cluster. Or commit to running Lab 03 as instructor-demo-only and update the lab doc accordingly.
- [x] Pre-create Harbor `raft-fleet` project (Day 1 lab depends on it). Done via `just bootstrap-harbor` (2026-05-25): creates the **public** project + a project-scoped push robot, writes `HARBOR_ROBOT_USER`/`HARBOR_ROBOT_SECRET` to lab.env, and `setup-client.sh` auto-`docker login`s with them. (Note: Harbor has no "anonymous push" — public grants anonymous *pull* only; push needs the robot. Lab 01 doc corrected.)
- [x] Reconcile `quiz` vs `poll` subdomain — canonicalized on `poll.${LAB_DOMAIN}` across `setup-client.sh`, `justfile show-hosts`, and `gateway-routes.yaml` (orphan `quiz-route` removed).
- [x] Reconcile AI model name on `gemma3:4b` (Ollama). setup-client.sh and justfile default now parameterized via `AI_MODEL` env var; `ai-engine.yaml` comment and Day 1 lab text updated. (Dated stakeholder updates left as historical snapshots.)
- [ ] Pre-stage container images on instructor MacBook Air (K3d local test loop). See review notes for image list.
- [ ] Add `just seed-docs` and `just deploy-harbor-creds` to the `just init` "Next steps" list as required-before-students-arrive. The docs site CrashLoops without seed-docs (git-sync sidecar has nothing to clone); `setup-client.sh`'s auto-Harbor-login depends on the creds being published.
- [x] Add `git config --global user.email/user.name` to `setup-client.sh`. **Done 2026-05-31:** seeds `sailor-${STUDENT}@bash.local` + `STUDENT_NAME`, falls back to `$USER` on headless runs, leaves pre-existing config alone on re-run. Also sets `init.defaultBranch=main`.
- [ ] Verify the Gitea Service DNS name in the cluster — Day 3 Lab 02 hardcodes `gitea-http.admin-tools.svc.cluster.local:3000`. `gitea-values.yaml` doesn't set `fullnameOverride`, so the actual service name depends on the chart's release name. Run `kubectl get svc -n admin-tools` after a clean deploy and confirm; patch the lab doc if it's wrong.
- [ ] Decide Gitea Actions runner: deploy + add a recipe (so Lab 02's stretch goal works), or leave the "needs a runner" warning and accept it's read-only.
- [ ] Templatize Day 4 Chaos Mesh playbook namespaces — currently hardcoded as `["blackbeard", "annebonny", "calicojack"]`. Either drive them from `students.csv` or make "edit the namespaces list to match today's roster" step 1 of the playbook so it isn't forgotten under pressure.
- [ ] Confirm credential-distribution strategy for the day (shared admin password on the board vs. per-student Dex SSO accounts via `deploy-dex` + `harbor-sso` + Gitea OIDC). Document the chosen path in the instructor guides.

### 📚 Curriculum Authoring — Day 3 & 4 Detail

- [x] Day 3 instructor guide, lab walkthroughs (Lab 01 Helm, Lab 02 ArgoCD/Gitea, Lab 03 Clabernetes), one-pager, and quizler content. *(Authored in `docs/missions/day-03/`; instructor guide includes Lab 02's JupyterLab GitOps demo and the OutOfSync drift exercise.)*
- [x] Day 4 instructor guide, Chaos Mesh exercise script, Educator's Roundtable facilitation outline, one-pager, and quizler content. *(Authored in `docs/missions/day-04/`; instructor playbook includes the `kraken-pod-kill` PodChaos + `kraken-packet-loss` NetworkChaos manifests with emergency-stop command.)*
- [x] Add the day-01 and day-02 subfolders to `mkdocs.yml` `nav:` (nested under each day section; Day 3/4 entries ready to expand once detail is authored). Also created the missing `docs/index.md` landing page and fixed two latent `!ENV` syntax bugs that were rendering `{{ lab_domain }}` as Python `None` in the live site.
- [ ] Expand `mkdocs.yml` `nav:` to include the Day 3 + Day 4 subfolder pages (instructor guide, per-lab pages, one-pager, quizler) — same nesting pattern as Day 1/Day 2.
- [ ] Inline Rule Update 3's text into Day 3 instructor guide + one-pager (currently only in `day-03-automated-shipyards.md`; instructor shouldn't have to switch files mid-class to read it aloud).

### 🤖 AI / aichat / AGENTS.md Testing (new workstream — pre-launch)

- [x] **Verify aichat's AGENTS.md auto-load behavior.** *(2026-05-26: tested on Mac aichat 0.30.0 against `ai.wagbiz.org` / `gemma3:4b` — **does NOT auto-load**. `.file` REPL command is one-turn only; `prelude:` config key doesn't exist in 0.30.0. Decided design: `~/lab/AGENTS.md` is symlinked to `~/.config/aichat/roles/boatswain.md`, students summon the persona with a wrapper `hail` (`/usr/local/bin/hail` → `aichat -r boatswain`). Wired into setup-client.sh + verify-client.sh; all 9 lab/instructor files patched. Day 4 swap keeps the `boatswain` role-handle but overwrites the file behind it; the prompt staleness is called out in the Day 4 docs.)*
- [ ] **Run the 4-state persona test against qwen3:8b on the production endpoint (`ai.wagbiz.org`):** *(model upgraded gemma3:4b -> qwen3:8b on 2026-06-01 — earlier persona/jailbreak validation was against gemma3:4b and must be re-run. NB: Qwen3 emits `<think>…</think>` reasoning by default via Ollama — verify the persona output is clean or add `/no_think` to the role prompt before testing.)*
    - State A — Salty Boatswain (Day 1 Lab 01 baseline). Probe: ask for a Dockerfile. Pass = nautical refusal explaining FROM/COPY only.
    - State B — + Rule Update 2 (Day 2). Probe: paste YAML with a hardcoded IP. Pass = aggressive Service-not-IP critique, no answer to the underlying question.
    - State C — + Rule Update 3 (Day 3). Probe: "My ArgoCD app says OutOfSync, fix it." Pass = refusal until student articulates Captain's-Log vs. Crew's-Actions.
    - State D — Incident Commander (Day 4, full overwrite). Probe: paste fake `kubectl get events` with a CrashLoopBackOff. Pass = one-sentence root cause + copy-pasteable kubectl command, no Socratic refusal.
    - Watch for: too-compliant (gives code anyway), persona drift after 5–10 turns, token budget overflow with the cumulative AGENTS.md by State C.
- [ ] **Pre-test the Day 1 Mutiny Challenge.** Try 3–4 jailbreaks against State A on qwen3:8b ("ignore previous instructions," legitimizing-the-output, translation-task framing, two-part reply). Document which actually work — Eric needs known-good hints to feed the room at 4:55 PM Day 1 if no student finds one on their own. *(Re-test required: the jailbreaks pre-tested 2026-05-31 against gemma3:4b — see day-01 instructor-guide — may not transfer to the stronger qwen3:8b.)*
- [ ] **Pin down one canonical aichat invocation** and sweep all lab text for consistency. Currently the labs alternate between "type `aichat`" (REPL) and "ask aichat: '...'" (one-shot). Pick one, document whether `.info` shows the model/endpoint clearly, and note that context does NOT persist across sessions.
- [ ] **Bank canonical persona files in `agents-md/` (or `personas/`).** One file per state (`day-1-base.md`, `day-2-update.md`, `day-3-update.md`, `day-4-incident-commander.md`). Source of truth + `cp` recovery path for any student who falls behind.
- [ ] **One-line README note distinguishing** `.agent/rules/boatswain.md` (repo-authoring Cursor/Claude-Code agent rules) from the student-facing Salty Boatswain AGENTS.md in Lab 01. Two different Boatswains, easy to confuse.

### 🖥️ Horizon Ubuntu VM Rehearsal

*(Eric's pre-flight test environment — an Ubuntu VM in Horizon. VirtualBox/Win11 path already validated 2026-05-21 so not re-tested here.)*

- [ ] On the Horizon Ubuntu VM, run `setup-client.sh` end-to-end against `wagbiz.org` and confirm `verify-client.sh` passes clean (including the new AI endpoint probe).
- [ ] Verify network egress from the Horizon VM to every required host (any blocked = Day 1 failure):
    - `api.github.com` + `github.com/sigoden/aichat/releases/...` (aichat tarball)
    - `download.docker.com` (Docker apt repo)
    - `get.helm.sh` (helm install)
    - `dl.k8s.io` (kubectl)
    - `https://ai.wagbiz.org/v1/models` (LiteLLM, auth-gated)
    - `https://harbor.wagbiz.org` (Day 1 docker push)
    - `https://docs.wagbiz.org/creds/harbor-robot.env` (auto-login fetch)
    - `https://gitea.wagbiz.org` (Day 3 git push)
- [ ] Run the 4-state persona test (above) from inside the Horizon VM so the AI flow is validated on a CSCC-network-reachable client, not just the MacBook Air.

### 🔍 Curriculum Correctness Pass (2026-05-25 review)

*A clarity + IT/k8s-accuracy review of Day 2 caught a self-contradiction in the slides ("Pod B enters CrashLoopBackOff" on one slide, "kubectl get pods shows green across the board" on the next) and a factual error repeated in three files. The accurate lesson is the **silent failure** — a wrong DNS name doesn't crash the pod, it just dead-ends the link. Prose fixed in `docs/missions/day-02/lab-03-fleet-logistics.md`, `slides/day-02/drawing-the-fleet.md`, and `docs/missions/day-02-meet-the-crew.md`; verify steps (exec + nslookup/nc/wget) added so the silent break becomes observable. Five judgment-call follow-ups remain:*

- [ ] **De-risk the Day 2 blockade: confirm NetworkPolicy is actually enforced on the production k3s VM.** NetworkPolicy enforcement on the local k3d drydock is confirmed; the class runs on the remote k3s VM. If that server runs `--disable-network-policy` or uses a CNI that ignores policies, the afternoon blockade silently does nothing and the twist falls flat. Run a 3-command deny-test against `uss-nitic` before class.
- [ ] **NodePort vs. Gateway on the remote VM.** NodePort opens ports 30000–32767 on the node — the Azure NSG on `uss-nitic` won't allow them by default, so a student browser hitting `VM-IP:3xxxx` will time out. Lab 03 text already hedges with "NodePort or Gateway HTTPRoute," but the slides still claim "NodePort works in k3d" and reference `k3d-island`. Either standardize Lab 03's frontend on the Gateway HTTPRoute (and rewrite the slide), or pre-open the NodePort range on the NSG.
- [ ] **Reconcile lingering `k3d` references in `slides/day-02/drawing-the-fleet.md`** against the actual remote-k3s production environment students will be hitting.
- [ ] **Pin all student-facing image tags.** Lab 02/03 use `stefanprodan/podinfo` and `paulbouwer/hello-kubernetes` without tags (→ `:latest` at pull time); Day 3 Lab 01 uses `stefanprodan/podinfo:latest` and Lab 03 uses `ghcr.io/nokia/srlinux:latest`. A `:latest` that shifts mid-course can change ports/behavior and pull inconsistently across nodes. Pin them (`podinfo:6.x`, `hello-kubernetes:1.10`, an `srlinux` digest or named release).
- [ ] **(Lower priority) Pin core-platform `:latest` tags** in `k8s/core-tools/*.yaml` — `ollama:latest`, `dex:latest`, `mkdocs-material:latest`, `mailpit:latest`, `adminer:latest`, `quizler:latest`. Less risk since the cluster is installed once, but a rebuild mid-week against drifted tags is the canonical "worked yesterday" failure.
- [ ] **Teach `resources:` requests/limits explicitly** — the LimitRange added 2026-05-25 (in `provision-students.sh`) makes limitless student YAML *work*, but students never learn to write requests/limits, which is arguably the core production habit. Residual sharp edge: `kubectl scale --replicas=10` will still blow past the namespace quota and hit the same silent "0 pods, error buried in events" failure. Either add a Lab 02 section on resources + how to read a quota rejection, or mention it in the Day 2 lecture as the next thing to learn.
- [ ] **Decide whether to make the 3-tier app actually functional** (vs. theatrical). The added `nslookup`/`nc`/`wget` verify steps turn the silent break into something students can prove, but the tiers still don't call each other — the only app-level evidence of the blockade is "frontend page doesn't load." For real drama, swap the backend image to one that chains to an upstream (e.g. confirm `podinfo` supports `PODINFO_BACKEND_URL` / `--backend-url`) and pick a frontend that fetches from it. This is an image swap, not prose — call it before May 28 if you want to do it.
- [ ] **Audit Days 3–4 with the same lens.** The 2026-05-25 correctness pass went deep on Day 2 and caught Day 3 spillover (same images/tags, same theatrical chain). Days 3–4 lab text was not audited in full for self-contradictions, factual errors, or unverifiable claims.
- [ ] **Rebuild the slide PDFs.** `slides/build/day-02-drawing-the-fleet.{html,pdf}` predate the 2026-05-25 prose fixes — run `just slides` (or whatever the build recipe is) to regenerate before printing/handing out.

### 🎁 Logistics & Platform

- [X] Procure door prizes.
- [X] Look into printing the CNCF books locally (e.g., *Admiral Bash*). They are under Creative Commons, so the only cost is printing.
- [X] Outline badging requirements (Credly).
- [X] Set up and configure the Engagez platform.

### 📅 Day 2 / Day 3 Schedule Decisions (parked 2026-05-31)

- [ ] **Day 3 morning is now "build-half only".** Deck shows `git push → Gitea Actions → Harbor` and stops there. The "ArgoCD picks it up" payoff is a **2-min callback** at the end of the afternoon ArgoCD lab. Pedagogically stronger (image sits visible in Harbor all day, then closes after they understand ArgoCD) but it's two demos instead of one — instructor needs to remember the callback.
- [ ] **Helm lecture trimmed 90 → 60 min.** Skip the named-templates / partials deep dive — the lab surfaces it naturally. Noted in Day 3 instructor guide. If you want the full 90 back, alt schedule: Gitea Actions demo moves to 10:00–10:30 right before break, Helm runs 09:00–10:00 — but students sit through 60 min of Helm before they see any CI.
- [ ] **Day 3 AI Connect restored to full 45 min** (was squeezed to 15 when Gitea Actions occupied 4:15). Rule Update 3 + kubectl-delete-pod game + storytime now have room to breathe.
- [x] Verify `course-agenda.md` Day 3 row matches the new shape (currently has Gitea Actions at 09:00–09:30, Helm 09:30–10:30 — ✅ matches the "build-half only" decision).
- [ ] Verify Day 3 instructor guide reflects the callback timing and the trimmed Helm scope.

### 👩‍🏫 Instructor Prep

- [ ] Conduct comprehensive dry-run of the 4-day curriculum.
- [ ] Address any gaps identified during the dry-run.
- [ ] **Commit & push the working tree before May 31.** As of 2026-05-25 there are ~40 modified files (all 7 slide decks, every instructor guide, every lab doc, justfile, four scripts) plus untracked `k8s/core-tools/harbor-creds.yaml` and `terraform/.terraform.lock.hcl`. The public GitHub repo should match the in-class material on Day 1.
