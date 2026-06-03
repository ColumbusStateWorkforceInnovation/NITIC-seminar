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

## 📝 Captain's Log (Notes)

*(What's the first piece you'll take home? Sketch your fork plan here...)*

<br><br><br><br><br><br><br><br>
