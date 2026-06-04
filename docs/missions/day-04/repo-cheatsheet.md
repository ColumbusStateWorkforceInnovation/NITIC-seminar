# Make It Your Own: Repo Cheat Sheet

```text
        _____________________
       |  ⚓  THE  WHOLE  |
       |      ISLAND      |
       |   in one repo    |
       |_________________|
        |  fork · config |
        |  deploy · teach|
       ~~~~~~~~~~~~~~~~~~~~~
```
*One repository holds the slides, the missions, the cluster, and the AI mate. Fork it, point it at your domain, and run this seminar — whole or in pieces — at your own college.*

> **🍴 Fork it — don't just clone it.** A clone is a dead end; a **fork** is your own GitHub copy where your changes live *and* where you pull seminar updates from. Set the original as `upstream` once:
> `git remote add upstream https://github.com/ColumbusStateWorkforceInnovation/NITIC-seminar.git`
> then `git fetch upstream && git merge upstream/main` anytime to get the latest. Your `lab.env` and rosters stay yours.

---

## 🗺️ The Map — what lives where

| Path | What it is |
| :--- | :--- |
| `justfile` | Every operational command. Run `just` to list them all. |
| `lab.env.example` | Config template → copy to `lab.env`, fill in, never commit. |
| `k8s/` | Manifests + Helm values for every service. |
| `scripts/` | Bootstrap, student provisioning, client setup. |
| `docs/` | The curriculum (MkDocs site). |
| `slides/` | These decks (Marp markdown → HTML + PDF). |
| `terraform/` | Optional OpenTofu stack for a cloud VM. |
| `certs/` | Generated lab TLS (private keys gitignored). |

---

## ✏️ The 3 Files You Edit

* **`lab.env`** — your institution in one file. `SERVER_IP` **blank = local k3d**, **set = remote SSH**. Also set `LAB_DOMAIN`, `AI_API_KEY`, the `*_ADMIN_PASSWORD`s, and `ORG_*` branding.
* **`scripts/students.csv`** — your roster: `username,display_name,email`. Feeds `just provision`.
* **`k8s/core-tools/dex.yaml`** — the SSO roster (same usernames as the CSV). Add a hash with `just dex-hash 'password'`.

> Both rosters are **gitignored** (they hold PII). Copy each from its `*.example` template.

---

## 🚀 Deploy In Order (local path)

* **Configure:** `cp lab.env.example lab.env` → edit
* **Validate:** `just init`
* **Cluster:** `just bootstrap-k3d`
* **TLS:** `just cert` → `just push-cert`
* **Core:** `just deploy-core` (gateway, AI, docs, polls)
* **Tools:** `just deploy-dex` → `deploy-gitea` → `deploy-harbor` → `deploy-argocd` → `deploy-rancher`
* **AI model:** `just pull-model`
* **Students:** `just provision` (preview first with `just provision-dry`)

> Run `just` with no arguments for the full, grouped command reference.

---

## 🛠️ Author Commands

* **Preview the course site:** `just serve-docs` → `http://localhost:8000`
* **Render every slide deck:** `just slides` (HTML + PDF + gallery)
* **Hash an SSO password:** `just dex-hash 'their-password'`
* **Provision one student:** `just provision-one <username>`
* **Play the student role:** `bash scripts/setup-client.sh`

---

## 🏴‍☠️ Day 4 Capstone Commands (the Pirate Strikes)

* **Install the attack platform:** `just deploy-chaos-mesh`
* **Sabotage every crew's repo (fragile baseline):** `just normalize-repos`
* **Launch the attack:** `just chaos-strike` (recurring pod-kill + pod-failure, all crews)
* **Escalate one/all crews:** `just chaos-stress [name]` (CPU saturation)
* **See what's running:** `just chaos-status`
* **Kill switch / end the game:** `just chaos-calm`
* **Grade a crew:** `./scripts/grade-cluster-recovery.sh student-<crew>`
* **After class:** `just teardown-chaos-mesh`

---

## 🤖 The AI Mate is a File

* The persona is **`AGENTS.md`** — plain markdown, not a model setting.
* Students summon it: `aichat -r boatswain` (the role symlinks to `AGENTS.md`).
* **Rewrite the file → rewrite the TA.** The Day 4 Socratic-Boatswain-to-Incident-Commander swap is the proof.
* Author your own: a syllabus enforcer, a code reviewer, a debate partner.

---

## 🧩 Reuse In Parts

* **Just the slides** — fork `slides/`, keep the Marp + theme pipeline.
* **Just the AI persona** — drop `AGENTS.md` + `aichat` into any course.
* **Just the capstone** — lift the Chaos Mesh "Pirate Strikes" self-grading exam.
* **Just the infra** — run the `justfile` + `k8s/` stack, bring your own labs.
* **The whole seminar** — fork, set `lab.env`, `just` your way to a classroom.

> Full walkthrough: **`docs/make-it-your-own.md`** and the repo `README.md`.

---

## 🤖 Ask an AI to Help You Fork It

The repo is agent-legible (markdown + `justfile` + `AGENTS.md`). Open it in an
agentic IDE (**Antigravity**, Claude Code, Cursor) or paste the GitHub URL into
Claude/Gemini, then:

```text
Read this repo (README.md, docs/make-it-your-own.md, the justfile, docs/missions/).
It's a forkable DevOps seminar. I want to teach <FORMAT> on <TOPIC> for <AUDIENCE>.
1) What can I reuse as-is?  2) What do I cut?  3) What's missing & where does it go?
Give me a session-by-session outline citing specific repo files.
```

> Example: *"I want to teach a DevOps class focused on **GitOps** — what could I use from this repo?"*

---

## 📝 Captain's Log (Notes)

*(What's the first piece you'll take home? Sketch your fork plan here...)*

<br><br><br><br><br><br><br><br>
