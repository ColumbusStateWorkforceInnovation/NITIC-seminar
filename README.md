# ⚓ Admiral Bash's Island Adventure

A 4-day cloud-native DevOps intensive — and the self-contained Kubernetes lab it runs on.

This repository holds **both halves** of the seminar: the curriculum (a MkDocs course
site under `docs/`) and the infrastructure-as-code that stands up the shared lab
cluster every student works in. It is built to be **portable** — clone it, point it
at your own server and domain, and run the seminar at your own institution.

The lab is a single k3s/k3d Kubernetes cluster running a full DevOps toolchain.
Everything is driven by a `justfile`, so a complete deployment is a short, ordered
list of `just` commands.

---

## What gets deployed

| Service | Purpose | Address |
|---|---|---|
| **Rancher** | Cluster UI, kubeconfig distribution | `rancher.<domain>` |
| **Gitea** | Internal Git server | `gitea.<domain>` |
| **Harbor** | Container registry | `harbor.<domain>` |
| **ArgoCD** | GitOps / continuous delivery | `argocd.<domain>` |
| **Dex** | Single sign-on (OIDC) | `sso.<domain>` |
| **Ollama + LiteLLM** | AI engine ("Socratic Boatswain") | `ai.<domain>` |
| **MkDocs** | The course site you are reading | `docs.<domain>` |
| **Grafana + Loki** | Logs and metrics | `grafana.<domain>` |
| **Mailpit** | Mock SMTP inbox | `mailpit.<domain>` |
| **Adminer** | Database UI | `db.<domain>` |
| **Quizler** | In-class flash polls | `poll.<domain>` |

TLS, routing, and chaos tooling — cert-manager, the Traefik Gateway API, and
Chaos Mesh — are deployed alongside these.

---

## Repository layout

| Path | What it is |
|---|---|
| `justfile` | Every operational command. Run `just` with no arguments to list them all. |
| `lab.env.example` | The configuration template — copy to `lab.env` and fill in. |
| `k8s/` | Kubernetes manifests and Helm values for every service. |
| `scripts/` | Cluster bootstrap, student provisioning, and client setup scripts. |
| `docs/` | The seminar curriculum (MkDocs site). |
| `terraform/` | Optional OpenTofu stack for provisioning a cloud VM. |
| `certs/` | Generated lab TLS certificates (private keys are gitignored). |

---

## Prerequisites

On the **machine you run `just` from** (your laptop or workstation):

- [`just`](https://just.systems) — the command runner (`brew install just`)
- `kubectl` and `helm`
- `envsubst` — ships with GNU gettext (`brew install gettext` on macOS). The
  deploy recipes template manifests with it and will fail without it.
- `openssl`, `curl`, `jq`, and `ssh` / `scp` — usually already installed
- **Local path only:** Docker, plus `k3d` (auto-installs if missing)
- **Remote path only:** an Ubuntu 22.04+ server reachable over SSH

`just init` checks most of these for you. `direnv` and Python 3 + `pip` are
optional but make the local workflow smoother.

---

## 1. Configure

```sh
cp lab.env.example lab.env
# then edit lab.env
```

`lab.env` is gitignored — it holds your institution's values and never gets
committed. The single most important field is **`SERVER_IP`**, because it
selects the deploy target automatically:

- **`SERVER_IP` blank** → LOCAL mode: everything runs against a k3d cluster on
  this machine.
- **`SERVER_IP` set** → REMOTE mode: recipes run over SSH against that server.

Other fields worth setting before you deploy:

- `LAB_DOMAIN` — the domain used for every service URL above.
- `LAB_ADMIN_EMAIL` — contact address for Let's Encrypt certificate notices.
- `SERVER_USER` / `SERVER_SSH_KEY` — SSH login for the remote server.
- `ORG_NAME`, `ORG_UNIT`, `ORG_LOCALITY`, `ORG_STATE`, `ORG_COUNTRY` — branding
  baked into the TLS certificate.
- `AI_API_KEY` and `PASSWORD_PREFIX` — **change these from the defaults** before
  a real seminar.
- `RANCHER_TOKEN` — left blank for now; you generate it after Rancher is up
  (see step 3).
- `CLOUDFLARE_API_TOKEN` — only needed for trusted Let's Encrypt TLS.

Validate your config and tooling at any time:

```sh
just init
```

---

## 2. Deploy the lab

Pick the path that matches your `SERVER_IP` setting.

### Path A — Local k3d (laptop, no cloud account)

The fastest way to try the stack or develop curriculum. Leave `SERVER_IP` blank.

```sh
just bootstrap-k3d     # create the local cluster + Gateway API
just cert              # generate a self-signed wildcard cert
just push-cert         # load it into the cluster as the wildcard-tls secret
just deploy-core       # gateway, AI engine (CPU), Adminer, Mailpit, MkDocs, Quizler
just deploy-dex        # single sign-on
just deploy-gitea
just deploy-harbor
just deploy-argocd
just deploy-rancher    # heavy on a laptop — skip if you only need a smoke test
```

Local TLS is self-signed, so browsers will warn until you trust the lab CA in
`certs/`. To reach the services by name, add the lab hostnames to your
`/etc/hosts` pointed at `127.0.0.1`.

### Path B — Remote server (the real seminar)

Set `SERVER_IP`, `SERVER_USER`, and `SERVER_SSH_KEY` in `lab.env`, then run
these **in order**:

```sh
just init                 # 1. validate config + local tools
just bootstrap-server     # 2. install k3s (and the GPU driver, if present)
just deploy-gpu-plugin    # 3. ONLY if the server has an NVIDIA GPU
just deploy-cert-manager  # 4. TLS controller
just deploy-letsencrypt   # 5. issue the wildcard cert (needs CLOUDFLARE_API_TOKEN)
just deploy-core          # 6. gateway, AI engine, Adminer, Mailpit, MkDocs, Quizler
just deploy-dex           # 7. single sign-on
just deploy-gitea         # 8.
just deploy-harbor        # 9.
just deploy-argocd        # 10.
just deploy-rancher       # 11.
just harbor-sso           # 12. wire Harbor to Dex (needs Harbor + Dex up)
just pull-model           # 13. pull the AI model into Ollama
```

A few things to watch for:

- **Step 2 may reboot the server.** If it has an NVIDIA GPU, `bootstrap-server`
  installs the driver and reboots. Wait ~60 seconds and run `just
  bootstrap-server` again.
- **Step 5 takes a few minutes.** Let's Encrypt validates over DNS-01; watch
  the certificate become ready with
  `kubectl get certificate -n admin-tools -w` before moving to step 6.
- **No Cloudflare?** You can skip steps 4–5 and use a self-signed cert instead:
  run `just cert` and `just push-cert`, then have students trust the lab CA.

The justfile's built-in `init` help text only lists steps 1–6; the SSO and
Helm-deployed tools (Dex, Gitea, Harbor, ArgoCD, Rancher) are separate recipes.
The sequence above is the complete path.

---

## 3. Add your students

The lab has **two rosters**, and a student normally belongs in both:

1. **Dex SSO roster** — `k8s/core-tools/dex.yaml`, the `staticPasswords` list.
   This is the single sign-on identity used to log into Gitea, Harbor, ArgoCD,
   and Grafana. To add someone: generate a password hash with
   `just dex-hash 'their-password'`, add an entry, then run `just deploy-dex`.

2. **Rancher provisioner roster** — `scripts/students.csv`, in
   `username,display_name,email` format. `just provision` reads this file and
   creates each student's Rancher account, project, namespace, and resource
   quota, then writes a printable credential card to `/tmp/creds/`.

`scripts/students.csv` is gitignored — it holds real names and emails — so
create your working copy from the tracked template:

```sh
cp scripts/students.csv.example scripts/students.csv
```

The template ships with three `testcrew` rows (mirrored in the Dex roster), so
a fresh copy is ready to dry-run immediately — replace them with your real
roster before go-live. Keep each `username` identical across `students.csv`
and `dex.yaml`.

```sh
just provision-dry        # preview — no changes made
just provision            # create every student in scripts/students.csv
just provision-one alice  # provision a single student
```

`just provision` needs `RANCHER_TOKEN` in `lab.env`. Generate it after Rancher
is running: log into the Rancher UI, set the admin password, then create an API
key under **Account → API Keys**.

> **Note:** `scripts/students.csv` is gitignored because it holds student PII.
> The tracked `scripts/students.csv.example` is the shareable template.

---

## 4. Students join the island

Each student works inside their own Linux VM. They run one script to install
the toolkit, wire up `/etc/hosts`, and load their kubeconfig:

```sh
bash setup-client.sh <SERVER_IP>
```

`just show-hosts` prints the `/etc/hosts` block for manual distribution, and
the credential cards from step 3 walk each student through first login.

---

## The AI engine — CPU vs GPU

The "Socratic Boatswain" runs `gemma3:4b` through Ollama + LiteLLM. The model is
small (~3.3 GB) and **runs fine on CPU** — no GPU is required to teach the
seminar, it is just slower to respond.

For GPU acceleration, run `just deploy-gpu-plugin` so Kubernetes can schedule
the card. Note that the remote `k8s/core-tools/ai-engine.yaml` requests a GPU
by default — **if your server has no GPU, remove the `runtimeClassName: nvidia`
and `nvidia.com/gpu` lines from that file**, or the Ollama pod will stay
`Pending`. (The local k3d path strips those lines automatically.)

---

## Previewing the curriculum

To read or edit the course site locally:

```sh
pip install -r requirements.txt
just serve-docs           # serves at http://localhost:8000
```

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `envsubst: command not found` | Install GNU gettext (`brew install gettext`). |
| `just provision` fails on auth | `RANCHER_TOKEN` is missing or stale — regenerate it from the Rancher UI. A freshly redeployed Rancher invalidates old tokens. |
| Ollama pod stuck `Pending` | Server has no GPU but `ai-engine.yaml` requests one — see the AI engine section above. |
| Certificate never goes `Ready` | Check `CLOUDFLARE_API_TOKEN`, or fall back to the self-signed `just cert` flow. |
| `bootstrap-server` seems to hang | It rebooted to load the GPU driver — wait ~60s and run it again. |
| `kubectl` hits the wrong cluster | Point `KUBECONFIG` at the project's `.kube/config` (see `.envrc.example`). |

Run `just` with no arguments for the full command reference.
