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

The fastest way to try the stack, develop curriculum, or **learn the lab by
running it yourself** before standing up a real classroom server. Leave
`SERVER_IP` blank in `lab.env` so every recipe targets your local k3d cluster.

Total wall time on a 2024-era laptop: ~30 minutes, mostly waiting for image
pulls. You can stop after `deploy-core` if you only need a smoke test.

```sh
just setup-env         # cp lab.env.example → lab.env  (if you haven't yet)
# edit lab.env: AI_API_KEY, DEX_DEMO_PASSWORD, HARBOR_ADMIN_PASSWORD,
#               RANCHER_BOOTSTRAP_PASSWORD, GITEA_ADMIN_PASSWORD,
#               GRAFANA_ADMIN_PASSWORD — every deploy recipe refuses to run
#               until its corresponding placeholder is replaced.
just init              # validate config + tools
just bootstrap-k3d     # ~2 min — local cluster + Gateway API
just cert              # generate a self-signed wildcard cert
just push-cert         # load it into the cluster as the wildcard-tls secret
just deploy-core       # ~3 min — gateway, AI engine (CPU), Adminer, Mailpit, MkDocs, Quizler
just deploy-dex        # ~30 s — single sign-on
just deploy-gitea      # ~2 min
just deploy-harbor     # ~5 min — heaviest of the three
just deploy-argocd
just deploy-rancher    # heavy on a laptop — skip if you only need a smoke test
just pull-model        # ~5 min — pulls gemma3:4b into Ollama (CPU)
```

Local TLS is self-signed, so browsers will warn until you trust the lab CA in
`certs/`. To reach the services by name, add the lab hostnames to your
`/etc/hosts` pointed at `127.0.0.1` (`just show-hosts` prints the block).

Once you can hit `https://gitea.<your domain>`, `https://harbor.<your domain>`,
and `https://docs.<your domain>` from your browser, the cluster is working —
jump to **§4. Play the student role** below to walk through Lab 00 yourself.

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
- **`harbor-sso` only needs Harbor + Dex.** It's listed at step 12 for
  readability, but you can run it as soon as both are Ready — no need to wait
  for Rancher.
- **Rancher SSO is a manual step.** Unlike the other tools, Rancher's auth
  provider can't be set via Helm or a recipe — after step 11, enable *Generic
  OIDC* by hand in the Rancher UI (client `rancher` / secret
  `rancher-oidc-secret`). It's the one piece of "click-ops" in the stack; the
  [Day 3 SSO walkthrough](docs/missions/day-03/sso-walkthrough.md) has the exact
  form fields. Optional — students log into Rancher with the local accounts
  `just provision` creates, so you only need this if you want Dex SSO there too.

The justfile's built-in `init` help text only lists steps 1–6; the SSO and
Helm-deployed tools (Dex, Gitea, Harbor, ArgoCD, Rancher) are separate recipes.
The sequence above is the complete path.

---

## 3. Add your students

The lab has **two rosters**, and a student normally belongs in both:

1. **Dex SSO roster** — `k8s/core-tools/dex.yaml`, the `staticPasswords` list.
   This is the single sign-on identity used to log into Gitea, Harbor, ArgoCD,
   and Grafana. (Rancher is *not* on this list by default — students log into it
   with the local accounts below, not Dex; see the manual OIDC note in §2.) To
   add someone: generate a password hash with `just dex-hash 'their-password'`,
   add an entry, then run `just deploy-dex`.

2. **Rancher provisioner roster** — `scripts/students.csv`, in
   `username,display_name,email` format. `just provision` reads this file and
   creates each student's local Rancher account, project, namespace, and
   resource quota, then writes a printable credential card to `/tmp/creds/`.

**Both rosters are gitignored** — they hold real names and emails — so create
your working copies from the tracked templates:

```sh
cp k8s/core-tools/dex.yaml.example   k8s/core-tools/dex.yaml
cp scripts/students.csv.example      scripts/students.csv
```

Each template ships with a `test` user plus a small pirate crew (`blackbeard`,
`annebonny`, `calicojack`), mirrored across both files, so a fresh copy is ready
to dry-run immediately — replace the pirates with your real roster before
go-live. Keep each `username` identical across `students.csv` and `dex.yaml`.

```sh
just provision-dry        # preview — no changes made
just provision            # create every student in scripts/students.csv
just provision-one alice  # provision a single student
```

### Generating `RANCHER_TOKEN`

`just provision` needs `RANCHER_TOKEN` in `lab.env` — a Rancher API key with
**admin, cluster-wide** rights (it creates users, assigns global roles, and
makes projects/namespaces). Generate it *after* Rancher is up:

1. Log into the Rancher UI as the **`admin`** (bootstrap) user and set the admin
   password if prompted. The token inherits your permissions, so it must be the
   admin account — a `sailor-*` student token can't create users.
2. Go to **profile menu (top-right) → Account & API Keys → Create API Key**, and
   fill the form:

   | Field | Value | Why |
   |---|---|---|
   | **Description** | e.g. `provision-students (lab setup)` | Just a label so you can find/revoke it later. |
   | **Scope** | **No Scope** | "Scope" pins a token to one downstream cluster; provisioning uses Rancher's *global* management API (`/v3/users`, `/v3/projects`), so it must stay unscoped. |
   | **Automatically expire** | 30 days (or no expiry) | The 8-day default can lapse mid-seminar if you re-provision or reset students. A stale/expired token is the #1 `just provision` failure. |

3. Click **Create**. Rancher shows the secret **once** — copy the **Bearer
   Token** (the full `token-xxxxx:yyyyy` form, *not* just the Access Key) into
   `lab.env`:

   ```sh
   RANCHER_TOKEN=token-xxxxx:yyyyy
   ```

4. Verify before the real run: `just provision-dry` should list every student
   with no errors. A `401`/`403` means the token is scoped, expired, or not an
   admin token; `no available server` means Rancher itself is down (see
   Troubleshooting).

> **Note:** both `scripts/students.csv` and `k8s/core-tools/dex.yaml` are
> gitignored because they hold student PII. The tracked `*.example` files
> (`students.csv.example`, `dex.yaml.example`) are the shareable templates.

---

## 4. Students join the island

Each student works inside their own Linux VM. They clone this repo and run one
script that installs the toolkit (Docker, kubectl, Helm, k9s, Fish, aichat,
…) and loads their kubeconfig. On the production path (real public DNS for
`LAB_DOMAIN`) no `SERVER_IP` is needed — DNS does the resolution:

```sh
git clone https://github.com/ColumbusStateWorkforceInnovation/NITIC-seminar.git
cd NITIC-seminar
export AI_API_KEY=<key from the board>
bash scripts/setup-client.sh
```

Self-hosters running k3d on a laptop, or any setup without public DNS for the
lab domain, opt in to `/etc/hosts` pinning by also exporting `SERVER_IP`:

```sh
export AI_API_KEY=<key from the board>
export SERVER_IP=<your lab server IP>
bash scripts/setup-client.sh
```

> **The `AI_API_KEY` export is mandatory.** If you skip it, the script falls
> through to a placeholder and `aichat` will return 401 in Lab 00 Part 6 — a
> failure that surfaces 10 minutes after the script "succeeds." The script
> aborts up front when the key is missing or still the placeholder; if it
> didn't (older clone), see the aichat-401 row in Troubleshooting.

`just show-hosts` prints the `/etc/hosts` block for that fallback path, and the
credential cards from step 3 walk each student through first login.

---

## 5. Play the student role (test the experience yourself)

The fastest way to know what you're teaching is to run `setup-client.sh`
against your own k3d cluster as if you were a student. Do this *before* the
classroom session — it surfaces every gap you'd otherwise hit live.

```sh
# In a fresh shell (or, even better, a clean VirtualBox VM matching what
# your students will use — Lab 00 walks through building one).
export AI_API_KEY=<the value you set in lab.env>
export SERVER_IP=127.0.0.1     # or your lab server IP for the remote path
bash scripts/setup-client.sh
```

The shortcut for an already-provisioned cluster is `just test-client <ip>`,
which sources `lab.env` and injects the right values for you.

Then work through **Lab 00 → Lab 02** in the docs site yourself. Anything
that's confusing for you will be confusing for a room of instructors.

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
just serve-docs           # serves at http://localhost:8000
```

The recipe installs the MkDocs plugins (`requirements.txt`) on first run, so
you don't need a separate `pip install` step.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `envsubst: command not found` | Install GNU gettext (`brew install gettext`). |
| `aichat` returns 401 / "Invalid Authentication" on a student VM | They didn't `export AI_API_KEY=…` before `setup-client.sh`, mistyped it, or re-ran the script (which only writes the config on the *first* install). Fix on the VM without rerunning the script: open `~/.config/aichat/config.yaml` in their editor of choice (e.g. `nano ~/.config/aichat/config.yaml`) and replace the `api_key:` value with the real key from the board, then save. Verify with `aichat "ahoy"`. The `AI_API_KEY` value in your `lab.env` is the source of truth — anything else won't match LiteLLM's `master_key`. |
| `just provision` fails on auth | `RANCHER_TOKEN` is missing or stale — regenerate it from the Rancher UI. A freshly redeployed Rancher invalidates old tokens. |
| Rancher returns `{"data":"no available server"}` / 503; pod in `CrashLoopBackOff` | The `v1.ext.cattle.io` APIService is `False (MissingEndpoints)`, stalling cluster API discovery so Rancher's `/healthz` times out and the kubelet keeps killing it (a restart loop that doesn't self-heal). Fix: `kubectl delete apiservice v1.ext.cattle.io` then `kubectl -n cattle-system rollout restart deploy/rancher`. Rancher re-registers the APIService once it reaches Ready. See the Day 3 instructor guide. |
| Ollama pod stuck `Pending` | Server has no GPU but `ai-engine.yaml` requests one — see the AI engine section above. |
| Certificate never goes `Ready` | Check `CLOUDFLARE_API_TOKEN`, or fall back to the self-signed `just cert` flow. |
| `bootstrap-server` seems to hang | It rebooted to load the GPU driver — wait ~60s and run it again. |
| `kubectl` hits the wrong cluster | Point `KUBECONFIG` at the project's `.kube/config` (see `.envrc.example`). |

Run `just` with no arguments for the full command reference.
