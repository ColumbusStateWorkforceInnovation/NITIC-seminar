---
marp: true
auto-scaling: false
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 4 · Make It Your Own"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 4 · Lecture & Demo · ~25 minutes

# Make It Your Own

## Forking the Island: take the whole seminar — or just the parts you want

*Three days you sailed this ship. This morning, here are the keys.*

<!-- Open the final morning by reframing the whole week. For three days they were students in this curriculum. The real deliverable was never the slides or the lab exercises — it was the repository that produces all of it. This 25 minutes is a guided tour of that repo, aimed squarely at them as builders of their own courses. Keep it concrete and unhurried; the cheat sheet in their hands is the map they keep. -->

---

## The real takeaway is a git repo

- Everything you have touched this week — the slides, the lab missions, the cluster, the AI mate — lives in **one repository**.
- It is **public**. You can clone it today and run this exact seminar at your own college.
- It is **modular**. Take the whole thing, or lift one piece into a course you already teach.
- This session is the map. Four questions:
  - **Where is everything?** (the layout)
  - **What do I change?** (`lab.env`)
  - **How do I run it?** (the `justfile`)
  - **How do I make it *mine*?** (docs, slides, the AI persona)

<!-- Set expectations: this is not a deep technical tutorial — it is an orientation so they leave knowing what to open first. Hand out the printed Repo Cheat Sheet now; tell them every command on these slides is on that page. -->

---

<!-- _class: chapter -->

#### Part I

# One repo, both halves

```text
       ____________________________
      |  curriculum  |    infra    |
      |   docs/      |   k8s/      |
      |   slides/    |  justfile   |
      |______________|_____________|
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

> *One hull carries both the cargo and the crew.*

---

## The map: what lives where

| Path | What it is |
|---|---|
| `justfile` | Every operational command. `just` with no args lists them all. |
| `lab.env.example` | The config template — copy to `lab.env`, fill in, never commit. |
| `k8s/` | Kubernetes manifests + Helm values for every service. |
| `scripts/` | Cluster bootstrap, student provisioning, client setup. |
| `docs/` | The curriculum — a MkDocs site (missions, one-pagers, quizzes). |
| `slides/` | These decks — Marp markdown → HTML + PDF. |
| `terraform/` | Optional OpenTofu stack to provision a cloud VM. |
| `certs/` | Generated lab TLS (private keys gitignored). |

<!-- Walk the table top to bottom — it mirrors the cheat sheet exactly. The single sentence to land: curriculum and infrastructure are versioned together, so a syllabus change and a cluster change travel in the same commit. That is the whole pitch in one line. -->

---

<!-- _class: chapter -->

#### Part II

# The one knob that matters

# `lab.env`

> *Set the heading once; every recipe sails by it.*

---

## `lab.env` — your institution in one file

```sh
cp lab.env.example lab.env     # gitignored — holds YOUR values
```

- **`SERVER_IP` blank → LOCAL mode** — everything runs on a k3d cluster on your laptop.
- **`SERVER_IP` set → REMOTE mode** — the same recipes run over SSH against your server.
- The other fields you actually edit before a real class:
  - `LAB_DOMAIN` — the domain behind every service URL.
  - `AI_API_KEY`, `*_ADMIN_PASSWORD` — **change these from the defaults.**
  - `ORG_*` — branding baked into your TLS certificate.
- One file selects laptop-demo vs. full classroom. Nothing else changes.

<!-- The big idea: the same codebase runs on a MacBook for curriculum development and on a GPU server for the live class — the only difference is whether SERVER_IP is filled in. Tell them to clone it tonight and run LOCAL mode; they will have the whole stack on their laptop in ~30 minutes. -->

---

<!-- _class: chapter -->

#### Part III

# The control panel

# the `justfile`

> *A complete deployment is a short, ordered list of `just` commands.*

---

## `just` — the whole lab as commands
<!-- _class: code-sm -->

```sh
just                  # list every recipe, grouped and described
just init             # validate your config + tooling
just bootstrap-k3d    # stand up a local cluster
just deploy-core      # gateway, AI engine, docs, polls...
just deploy-gitea     # ...then each tool, in order
just provision        # create every student from a roster CSV
just serve-docs       # preview the curriculum at :8000
just slides           # render every deck to HTML + PDF
```

- You never memorize `kubectl`/`helm` incantations — the recipes are the runbook.
- Read any recipe to see exactly what it does. The `justfile` **is** the documentation.

<!-- Demo option if you have a terminal up: run `just` live so they see the grouped command list scroll by. The point is that the operational knowledge of the whole lab is captured as runnable, readable text — not in someone's head. -->

---

## The toolbox — and every tool is swappable

| Service | Role | Swap it for |
|---|---|---|
| **Rancher** | Cluster UI / kubeconfig | any K8s dashboard |
| **Gitea** | Git server | GitHub / GitLab |
| **Harbor** | Image registry | any OCI registry |
| **ArgoCD** | GitOps delivery | Flux |
| **Dex** | Single sign-on | your campus IdP |
| **Ollama + LiteLLM** | The AI mate | any OpenAI-compatible API |
| **MkDocs** | Course site | any static-site generator |
| **Quizler** | In-class polls | your LMS quiz tool |

<!-- The message is freedom, not lock-in: every box is open-source and self-hosted, and each one is a deployment you control. If your campus already runs GitLab, point the labs at it. Nothing here is a black box you have to accept whole. -->

---

<!-- _class: chapter -->

#### Part IV

# Making it yours

# docs · slides · the AI mate

> *The parts you will actually rewrite.*

---

## The curriculum is markdown: `docs/`

- The course site is **MkDocs** — every mission, one-pager, instructor guide, and quiz is a markdown file under `docs/`.
- Preview your edits live:

```sh
just serve-docs       # http://localhost:8000, reloads as you save
```

- Quizzes are plain `*.quizler` files loaded into the in-class poll app.
- Edit the markdown, commit, and — on a GitOps-wired cluster — the live site updates itself.

<!-- This is "GitOps for your syllabus." A typo fix or a new lab is a commit, not an email to 30 students. serve-docs gives them the same instant-preview loop you used to build this. -->

---

## The slides are markdown too: **Marp**
<!-- _class: code-xs -->

```markdown
---
marp: true
theme: nautical
---

# A slide is a heading

- A bullet is a bullet
---
# The next slide starts after a triple-dash
```

- These decks are **plain text** — diffable, reviewable, no binary `.pptx`.
- The look comes from one shared theme: `slides/themes/nautical.css`.
- Render the whole set — HTML + PDF + the gallery page — with one recipe:

```sh
just slides
```

<!-- Hold up that this very deck is a markdown file rendered by `just slides`. Faculty who fear "rebuilding all the slides" should hear: you edit text, you re-run one command, every deck and PDF regenerates. Re-theme the whole seminar by editing one CSS file. -->

---

## The teaching mate is a file: `AGENTS.md`

- The "Socratic Boatswain" is not a model setting — it is a **markdown persona file**.
- Students invoke it with `aichat -r boatswain`; the role is a symlink to `AGENTS.md`.
- **Rewrite the file → rewrite the TA.** You saw the proof an hour ago:
  - 3 days: a Socratic mate that *refuses to hand over answers*.
  - Mid-incident: overwrite it into an **Incident Commander** that gives the exact fix.
- Author your own personas — a strict syllabus enforcer, a code reviewer, a debate partner.

<!-- Connect back to this morning's persona swap and the upcoming one in the attack. The faculty lesson: a local, file-based AI persona is a scalable TA you fully control — its behavior is text you can read, version, and tune for the moment. No prompt is hidden; the role IS the file. -->

---

<!-- _class: chapter -->

#### Part V

# Take all of it — or just a plank

> *You do not have to adopt the whole ship.*

---

## Reuse in parts

- **Just the slides** — fork `slides/`, keep the Marp + theme pipeline, write your own decks.
- **Just the AI persona** — drop the `AGENTS.md` + `aichat` pattern into any course.
- **Just the capstone** — lift the Chaos Mesh "Pirate Strikes" game as a self-grading exam.
- **Just the infra** — run the `justfile` + `k8s/` stack as a sandbox cluster, bring your own labs.
- **The whole seminar** — fork, set `lab.env`, `just` your way to a running classroom.
- Every piece stands alone because every piece is just files in a folder.

<!-- This is the slide that frees the reluctant. Most faculty will not run the entire stack on day one — and they do not have to. Name the smallest useful piece for each person in the room: a single deck, a single persona, a single lab. -->

---

<!-- _class: chapter -->

#### Part VI

# Let the agent help you remix it

> *You don't have to read the whole ship's manifest yourself.*

---

## The repo reads itself

- This repo is **agent-legible** by design:
  - the curriculum is **markdown**,
  - the operations are a self-documenting **`justfile`**,
  - the AI persona is a plain **`AGENTS.md`**.
- So point an agent *at the repo* and let it do the mapping:
  - open it in an agentic IDE — **Antigravity**, Claude Code, Cursor —
  - or paste the **public GitHub URL** into Claude or Gemini.
- Then ask: *"which parts of this fit the class I want to teach?"*

<!-- The reframe: forking is not a reading assignment. The same agent-legibility that lets the Boatswain help students lets a planning agent help YOU design a course. The repo already documents its own layout (this guide), so the agent starts informed. -->

---

## A prompt you can steal

```text
Read this repo (README.md, docs/make-it-your-own.md, the justfile,
docs/missions/). It's a forkable DevOps seminar. I want to teach
<FORMAT> on <TOPIC> for <AUDIENCE>.
  1) What can I reuse as-is?
  2) What should I cut?
  3) What's missing, and where would it slot in?
Give me a session-by-session outline citing specific repo files.
```

- Example: *"I want to teach a DevOps class focused on **GitOps** — what could I use from this repo?"*
- One prompt covers the whole room — each of you fills in your own format, topic, audience.
- Treat the answer as a **first draft to react to**, not gospel. You own the curriculum.

<!-- This same prompt is on the printed Repo Cheat Sheet. The angle-brackets are the trick: it generalizes to every faculty member's situation. -->

---

<!-- _class: chapter -->

#### Part VI · Demo

# Live: ask Antigravity

```text
   > "Teach me GitOps from this repo..."
          |
          +--> [ reading README.md ]
          +--> [ reading justfile ]
          +--> [ reading docs/missions/day-03/ ]
```

> *Watch it read the repo and build the outline in real time.*

---

## Demo — what you're watching

- The repo is open in **Antigravity**; the agent runs in the **Agent Manager**.
- I paste the prompt above with **GitOps** as the topic.
- Watch it:
  - **read** the README, the `justfile`, and the Day 3 GitOps labs;
  - **cite the actual files** it would reuse — the Helm lab, the ArgoCD lab, the Gitea Actions demo;
  - **draft a session outline** mapped to those files.
- The takeaway: this is how you'll plan your *own* fork — in minutes, not a weekend.

<!-- LIVE DEMO — keep it to ~3-4 minutes. Have the repo already open in Antigravity and the prompt in your paste buffer before the session. Narrate what the agent reads AS it reads it — that legibility IS the teaching point. FALLBACK: if the live run stalls or the wifi dies, cut to a prepared screenshot or saved transcript of the same prompt; do not debug live. Land it: "that outline is your starting draft — you edit it and you own it." -->

---

## Fork it — don't just clone it

- A **clone** is just a local copy — there's nowhere of *yours* on GitHub, and no clean way to get updates.
- A **fork** is *your* copy of the repo under your account or org:
  - your customizations live there,
  - and you can **pull updates** from the original as the seminar improves.
- One-time setup, then update anytime:

```sh
git remote add upstream \
  https://github.com/ColumbusStateWorkforceInnovation/NITIC-seminar.git
git fetch upstream && git merge upstream/main   # pull in the latest
```

> **Forking is how you get updates.** Your `lab.env`, rosters, and edits stay yours.

<!-- The single most important habit to leave them with: FORK, don't clone. Clone is a dead end — no updates, nowhere to push. A fork with an upstream remote means every fix and new lab the seminar ships is one `git fetch` away, without losing their own customizations. Say it plainly. -->

---

## The fork workflow, end to end
<!-- _class: code-xxs -->

```sh
# 1. Fork on GitHub, then clone YOUR fork
git clone https://github.com/<you>/NITIC-seminar.git

# 1b. Point "upstream" at the original (once) — your update channel
git remote add upstream https://github.com/ColumbusStateWorkforceInnovation/NITIC-seminar.git

# 2. Configure your institution
cp lab.env.example lab.env        # edit domain, passwords, AI key

# 3. Add your roster (both files, same usernames)
cp scripts/students.csv.example   scripts/students.csv
cp k8s/core-tools/dex.yaml.example k8s/core-tools/dex.yaml

# 4. Validate, deploy, provision
just init  &&  just bootstrap-k3d  &&  just deploy-core
just provision
```

- Full walkthrough lives in the repo: **`docs/make-it-your-own.md`** and the README.

<!-- These are the five moves. Do not read every line — point at the cheat sheet, where this same block is printed, and tell them the repo guide expands each step with the gotchas. The takeaway is that "stand up the seminar" is a short, ordered list, not a research project. -->

---

## Instructor Superpower

#### The repo is the platform

- **Version the curriculum and the cluster together** — one commit moves both.
- **Distribute the lab as a URL, not an install disk** — students `git clone` and run one script.
- **Run a local, file-based AI TA you fully control** — and re-tune it per lesson.
- You no longer wait for IT to bless a tool. You fork, you configure, you teach. The environments you can offer your students just expanded to *everything in this repo*.

<!-- The destination slide. Slow down. The hook is agency, not grievance: a single instructor with this repo can stand up an environment that used to require a department and a budget cycle. Put it to the room — what is the first piece you will take home? -->

---

<!-- _class: lead -->
<!-- _footer: "" -->

# It's yours now.

```text
   ~~~^~~~~~^~~~~~~^~~~~^~~~~~^~~~
  ~~~~~~^~~~~~~^~~~~^~~~~~~^~~~~~~~
   ~^~~~~~^~~~~~~^~~~~~^~~~~~^~~~~~
```

*Fork it tonight. And speaking of taking what isn't nailed down — the Pirate is almost aboard.*

<!-- Close the session and pivot to the Arsenal/Chaos material and the capstone. The button is a wink: they now have permission to take the whole ship, which is the perfect setup for a chaos game about defending it. Hand the floor back to the morning's attack build-up. -->
