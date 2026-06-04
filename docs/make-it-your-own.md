# Make It Your Own — Forking the Seminar

This repository is the whole seminar: the slides you sat through, the lab
missions you worked, the Kubernetes cluster you worked them on, and the AI mate
that helped you. It is public, and it is built to be **portable** — clone it,
point it at your own server and domain, and run "Admiral Bash's Island
Adventure" at your own institution. Or lift one piece into a course you already
teach.

This page is the long-form companion to the in-class *Make It Your Own* session
and the printed [Repo Cheat Sheet](missions/day-04/repo-cheatsheet.md). It walks
the same path with the gotchas filled in.

## One repo, both halves

The thing that makes this curriculum portable is that the **curriculum and the
infrastructure live in the same repository, under version control, together**. A
syllabus fix and a cluster change travel in the same commit. Nothing about the
course lives in someone's head, a shared drive, or a binary file you can't diff.

| Path | What it is |
| :--- | :--- |
| `justfile` | Every operational command. `just` with no arguments lists them all. |
| `lab.env.example` | The configuration template — copy to `lab.env`, fill in, never commit. |
| `k8s/` | Kubernetes manifests and Helm values for every service. |
| `scripts/` | Cluster bootstrap, student provisioning, and client setup scripts. |
| `docs/` | The curriculum — a MkDocs site (missions, one-pagers, quizzes, guides). |
| `slides/` | The instructor decks — Marp markdown rendered to HTML + PDF. |
| `terraform/` | Optional OpenTofu stack to provision a cloud VM. |
| `certs/` | Generated lab TLS certificates (private keys are gitignored). |

## Before you start: what you'll need

You drive the whole lab from one machine you control — call it the **control
node**. That can be your laptop (local mode) or a remote server you SSH into
(remote mode). The tools below install on the control node; students need none
of them (they get a one-line bootstrap script).

| Tool | Why it's here | Install |
| :--- | :--- | :--- |
| **`just`** | The command runner. The entire lab is `just` recipes. | macOS: `brew install just` · Linux/WSL: `curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \| bash -s -- --to ~/.local/bin` (or your package manager) |
| **Docker** | Local mode runs Kubernetes *inside* Docker. | macOS/Windows: Docker Desktop · Linux: Docker Engine |
| **`k3d`** | Wraps k3s in Docker for instant local clusters. Auto-installs if missing. | `brew install k3d` or `curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \| bash` |
| **`kubectl`** | Talk to the cluster. | `brew install kubectl` or the [official binary](https://kubernetes.io/docs/tasks/tools/) |
| **`helm`** | Installs most of the tools. | `brew install helm` or the [install script](https://helm.sh/docs/intro/install/) |
| **`envsubst`** | Recipes template manifests with it — they fail without it. | Ships with GNU gettext: `brew install gettext` / `apt install gettext-base` |
| `openssl`, `curl`, `jq`, `ssh`/`scp` | Certs, API calls, remote deploys. | Usually preinstalled |

Optional but smoother: **`direnv`** (auto-loads `.envrc`), **Python 3 + `pip`**
(for `just serve-docs`), and **OpenTofu** (`tofu`) if you provision the cloud VM
in `terraform/`. `just init` checks most of these for you and tells you what's
missing.

### Why these tools — the choices baked in

A few deliberate decisions shape the repo. If you fork it, it helps to know why
each is here so you can keep or swap it on purpose:

- **`just`, not `make`.** Recipes read like a runbook, there are no tab/`.PHONY`
  footguns, and `just` with no arguments self-documents every command. It is a
  single static binary on every OS.
- **`k3d` + `k3s`, for parity.** The classroom server runs **k3s** (a single
  lightweight Kubernetes binary, ideal for one VM). `k3d` runs that *same* k3s
  inside Docker on your laptop — so the cluster you develop against and the one
  you teach on behave alike. (Alternatives like `kind`/`minikube` would diverge
  from the production k3s.)
- **Marp for slides, MkDocs Material for docs.** Both are markdown, so the
  whole curriculum is diffable plain text under version control — re-theme every
  deck by editing one CSS file, fix a typo with a commit instead of an email.
- **Ollama + LiteLLM + `aichat` for the AI mate.** Self-hosted and
  OpenAI-compatible: no per-student API bill, and no student prompts leave the
  room. Point it at a hosted API later by changing one config.
- **Self-hosted Gitea / Harbor / ArgoCD / Dex.** They mirror the real
  industry tools students will meet, but you own every byte and there are no
  external accounts to provision for a class.
- **OpenTofu for the optional cloud VM.** The `terraform/` stack uses `tofu`
  (the open-source fork) — run it only if you want IaC to stand up the server.

### Your operating system

- **macOS** — the smoothest path. Install Homebrew and Docker Desktop, then the
  tools above. Everything in this guide works as written.
- **Linux** — fastest local clusters (native Docker Engine, no VM layer).
  Install `just`/`k3d` via the scripts above or your package manager; Docker via
  your distro's Docker Engine packages.
- **Windows — use WSL2.** The recipes assume a POSIX shell (`bash`) plus
  coreutils, so native PowerShell is not supported. Install **WSL2** with an
  Ubuntu distro, install **Docker Desktop with the WSL2 backend** (or Docker
  Engine inside the distro), then run *everything* — clone, `just`, the lot —
  from inside the WSL Ubuntu shell.

    !!! tip "Clone into the Linux filesystem"
        Put the repo under your WSL home (e.g. `~/NITIC-seminar`), **not** under
        `/mnt/c/...`. Cross-filesystem I/O on `/mnt/c` is slow and breaks file
        permissions and symlinks (the `aichat` persona symlink, for one).

## Two paths: laptop or server

The same codebase runs in two modes, and the only switch between them is whether
`SERVER_IP` is set in `lab.env`:

- **Local mode (curriculum development).** `SERVER_IP` blank → everything runs on
  a k3d cluster on your control node. This is the path for *writing* labs and
  slides, testing changes, and learning the stack. No cloud account, ~30 minutes
  to a full stack, and heavy pieces like Rancher are optional for a smoke test.
- **Remote mode (a classroom or shared dev server).** `SERVER_IP` set → the same
  recipes run over SSH against an Ubuntu 22.04+ server. This is the path for a
  live class: real public DNS for `LAB_DOMAIN`, Let's Encrypt TLS, an optional
  GPU for a snappier AI mate, and students reaching the lab over the network.

Develop locally, then point the *same* repo at a server when it's time to teach.

### DNS: pointing a domain at the server (remote mode)

Remote mode needs a name, not just an IP, because every service lives at its own
subdomain — `rancher.`, `gitea.`, `harbor.`, `argocd.`, `docs.`, `sso.`, and so
on, all under whatever you set as `LAB_DOMAIN`. You have two clean options:

- **Use a subdomain you control** — e.g. `lab.yourcollege.edu`. Ask campus IT to
  delegate that subdomain to a DNS provider you can manage (Cloudflare is the
  path this repo is wired for), so you can create records without touching the
  main campus zone. This is usually the easiest thing to get approved.
- **Use a domain you own** — e.g. `wagbiz.org` (what this lab ships with). Same
  mechanics, you just own the whole zone.

Either way, the DNS you create is the same:

- **One wildcard A record** is all you need: `*.lab.yourcollege.edu → <server
  public IP>`. The wildcard covers every service subdomain at once, so you never
  add records one by one as you deploy more tools. (Add an apex/base record too
  if you also serve something at the bare `LAB_DOMAIN`.)
- Set `LAB_DOMAIN` in `lab.env` to that hostname and **leave `SERVER_IP` set to
  the same server** — the recipes use it as the SSH target.

For **trusted HTTPS**, the lab issues a Let's Encrypt **wildcard** certificate
via the **DNS-01** challenge, which is why a DNS provider with an API token is
needed (`CLOUDFLARE_API_TOKEN`). The wildcard cert (`*.lab.yourcollege.edu`)
then secures every service with no per-subdomain setup. If you can't use DNS-01,
fall back to the self-signed flow (`just cert` → `just push-cert`) and have
students trust the lab CA.

!!! note "No public DNS at all?"
    Students can still reach the lab without DNS: set `SERVER_IP` and run
    `just show-hosts` to print an `/etc/hosts` block that pins every subdomain to
    the server IP. It works for a small room, but a wildcard A record is the
    clean classroom path — no per-machine edits, and real TLS.

## The one knob: `lab.env`

Everything that is specific to *your* institution lives in a single gitignored
file. Copy the template and edit it:

```sh
cp lab.env.example lab.env
```

The single most important field is `SERVER_IP` — it selects your deploy target
automatically (blank = local k3d, set = remote SSH), which is the laptop-vs-server
switch from the [Two paths](#two-paths-laptop-or-server) section above.

The other fields you will actually set before a live class:

- `LAB_DOMAIN` — the domain behind every service URL.
- `LAB_ADMIN_EMAIL` — contact address for Let's Encrypt certificate notices.
- `AI_API_KEY` and every `*_ADMIN_PASSWORD` — **change these from the defaults.**
  Each deploy recipe refuses to run until its placeholder is replaced.
- `ORG_NAME`, `ORG_UNIT`, `ORG_LOCALITY`, `ORG_STATE`, `ORG_COUNTRY` — branding
  baked into the TLS certificate.
- `RANCHER_TOKEN` — left blank at first; you generate it from the Rancher UI
  once Rancher is up (the README walks through this).
- `CLOUDFLARE_API_TOKEN` — only needed for trusted Let's Encrypt TLS.

Validate your config and tooling at any time with `just init`.

## The control panel: the `justfile`

You never have to remember raw `kubectl` or `helm` incantations. Every operation
is a named recipe, and a complete deployment is a short, ordered list of them.
Run `just` with no arguments to see every recipe, grouped and described. Read any
recipe to see exactly what it does — the `justfile` *is* the runbook.

A local deployment, start to finish:

```sh
cp lab.env.example lab.env   # then edit it
just init                    # validate config + tooling
just bootstrap-k3d           # stand up a local cluster + Gateway API
just cert                    # self-signed wildcard cert
just push-cert               # load it as the wildcard-tls secret
just deploy-core             # gateway, AI engine, docs, polls, Adminer, Mailpit
just deploy-dex              # single sign-on
just deploy-gitea            # Git server
just deploy-harbor           # image registry (the heaviest)
just deploy-argocd           # GitOps delivery
just deploy-rancher          # cluster UI (skip for a quick smoke test)
just pull-model              # pull the AI model into Ollama
```

The remote (real-server) path is the same shape with a few extra steps for
cert-manager and Let's Encrypt — see the README's "Path B" for the full ordered
list and the notes about GPU drivers and DNS-01 validation.

## The toolbox — and why every piece is swappable

The lab is a full DevOps toolchain, and every tool is open-source and
self-hosted. That means each one is a deployment *you* control — and each is
replaceable with whatever your campus already runs.

| Service | Role | A common swap |
| :--- | :--- | :--- |
| Rancher | Cluster UI, kubeconfig distribution | any Kubernetes dashboard |
| Gitea | Internal Git server | GitHub / GitLab |
| Harbor | Container registry | any OCI registry |
| ArgoCD | GitOps / continuous delivery | Flux |
| Dex | Single sign-on (OIDC) | your campus identity provider |
| Ollama + LiteLLM | The "Socratic Boatswain" AI engine | any OpenAI-compatible API |
| MkDocs | The course site | any static-site generator |
| Grafana + Loki | Logs and metrics | your existing observability stack |
| Quizler | In-class flash polls | your LMS quiz tool |

Nothing here is a black box you have to accept whole. If your students should
push to your existing GitLab, point the labs there.

## Making it yours: the parts you will rewrite

### The curriculum: `docs/`

The course site is **MkDocs**. Every mission, one-pager, instructor guide, and
quiz is a markdown file under `docs/`. Preview your edits with live reload:

```sh
just serve-docs   # http://localhost:8000
```

Quizzes are plain `*.quizler` files loaded into the in-class poll app. Because
the site is just markdown in the repo, a typo fix or a brand-new lab is a commit
— and on a GitOps-wired cluster the live site updates itself. That is "GitOps
for your syllabus."

### The slides: Marp

The decks are markdown too. Each deck is a `.md` file under `slides/`, and the
shared look comes from one theme file, `slides/themes/nautical.css`. Render the
whole set — HTML, PDF, and the gallery index — with one recipe:

```sh
just slides
```

Slides as plain text means they are diffable and reviewable, with no binary
`.pptx` to wrangle. Re-theme the entire seminar by editing one CSS file. (The
renderer uses the Marp CLI and needs a Chrome/Chromium install for PDF output.)

### The teaching mate: `AGENTS.md`

The AI mate is not a hidden model setting — it is a markdown **persona file**.
Students invoke it with `aichat -r boatswain`, where the `boatswain` role is a
symlink to `AGENTS.md`. Rewrite the file and you rewrite the TA. The Day 4
capstone makes this concrete: for three days the Boatswain is Socratic and
refuses to hand over answers; mid-incident you overwrite the same file into an
*Incident Commander* that gives the exact, copy-pasteable fix. Matching the AI's
behavior to the moment is itself a skill worth teaching — and because the
persona is text you can read and version, you can author your own: a strict
syllabus enforcer, a code reviewer, a debate partner. A worked example persona
lives in `examples/agents-md/`.

## Reuse in parts

You do not have to adopt the whole ship. Every piece stands alone because every
piece is just files in a folder:

- **Just the slides** — fork `slides/`, keep the Marp + theme pipeline, write
  your own decks.
- **Just the AI persona** — drop the `AGENTS.md` + `aichat` pattern into any
  course.
- **Just the capstone** — lift the Chaos Mesh "Pirate Strikes" game as a
  self-grading incident-response exam.
- **Just the infrastructure** — run the `justfile` + `k8s/` stack as a sandbox
  cluster and bring your own labs.
- **The whole seminar** — fork, set `lab.env`, and `just` your way to a running
  classroom.

## Let an AI agent help you remix it

You do not have to read this whole repo by hand to figure out what to take. It is
deliberately **agent-legible** — the curriculum is markdown, the operations are a
self-documenting `justfile`, and the AI persona is a plain `AGENTS.md`. Point an
agent at it and ask it to do the mapping for you. Open the repo in an agentic IDE
(**Google Antigravity**, Claude Code, Cursor), or just paste the public GitHub
URL into Claude or Gemini and let it read.

A reusable prompt — fill in the angle-bracket parts:

```text
Read this repository — start with README.md, docs/make-it-your-own.md, the
justfile, and docs/missions/. It is a complete, forkable DevOps seminar:
slides, hands-on labs, a Kubernetes lab cluster, and an AI teaching persona.

I want to teach <FORMAT, e.g. a 10-week course / a 2-day workshop> on <TOPIC>
for <AUDIENCE>. Help me reuse it:
  1. Which labs, slides, and tools here map to my topic — what can I take as-is?
  2. What should I cut or simplify to fit my scope and audience?
  3. What is missing that I would need to add, and where would it slot in?
Give me a session-by-session outline, citing the specific repo files for each session.
```

Sample questions that work well as a starting point:

- *"I want to teach a DevOps class focused on **GitOps** — what could I use from this repo?"*
- *"Build a 3-week **container fundamentals** unit from the Day 1–2 material only — no Kubernetes."*
- *"I have laptops, **no GPU and no cloud budget**. Which parts run locally, and what do I change in `lab.env`?"*
- *"Turn the Day 4 **chaos capstone** into a standalone graded assignment for my existing SRE course."*
- *"Rewrite the **`AGENTS.md`** persona into a strict syllabus enforcer for my class rules."*

The agent reads faster than you do and already knows the file layout from this
guide — treat its outline as a first draft to react to, not gospel. You own the
final curriculum; the agent just gets you to a working draft in minutes.

## The fork workflow, end to end

**Fork it — don't just clone it.** A *clone* is only a local copy with no home of
its own on GitHub: fine for a quick look, but there is nowhere of *yours* to push
your customizations, and no clean way to pull in improvements later. A **fork** is
your own copy of the repo under your account or organization — your changes live
there, and you can pull updates from the original whenever the seminar improves.

!!! tip "Forking is how you get updates"
    The seminar keeps evolving — new labs, fixes, better slides. Add the original
    repo as an `upstream` remote once, then `git fetch upstream` and merge
    whenever you want the latest. Your `lab.env`, your rosters, and your edits
    stay yours (they're gitignored or on your own branch), so updates don't
    clobber your institution's setup.

```sh
# 1. Fork on GitHub (the "Fork" button, top-right), then clone YOUR fork
git clone https://github.com/<you>/NITIC-seminar.git
cd NITIC-seminar

# 1b. Point "upstream" at the original — once — so you can pull updates later
git remote add upstream https://github.com/ColumbusStateWorkforceInnovation/NITIC-seminar.git

# 2. Configure your institution
cp lab.env.example lab.env          # edit domain, passwords, AI key

# 3. Add your roster — both files, identical usernames
cp scripts/students.csv.example     scripts/students.csv
cp k8s/core-tools/dex.yaml.example  k8s/core-tools/dex.yaml
#   add an SSO password hash with: just dex-hash 'their-password'

# 4. Validate, deploy, provision
just init
just bootstrap-k3d
just deploy-core
just provision                      # preview first: just provision-dry

# 5. Later: pull in upstream improvements (do this periodically)
git fetch upstream
git merge upstream/main             # review, resolve conflicts, commit
```

Both roster files are gitignored because they hold student names and emails —
always work from the tracked `*.example` templates, and keep each `username`
identical across `students.csv` and `dex.yaml`.

## Test it as a student before you teach it

The fastest way to know what you are teaching is to run the student bootstrap
against your own cluster as if you were a student:

```sh
export AI_API_KEY=<the value you set in lab.env>
export SERVER_IP=127.0.0.1
bash scripts/setup-client.sh
```

Then work through Lab 00 → Lab 02 yourself. Anything confusing for you will be
confusing for a room of instructors. The README's "Play the student role"
section has the details.

## Where to look next

- The repository [`README.md`](https://github.com/ColumbusStateWorkforceInnovation/NITIC-seminar)
  — the full configure / deploy / roster / troubleshooting reference.
- The printed [Repo Cheat Sheet](missions/day-04/repo-cheatsheet.md) — the
  one-page version of everything above.
- Run `just` with no arguments — the complete, grouped command reference.
