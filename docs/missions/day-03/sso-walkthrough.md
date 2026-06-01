# Instructor Walkthrough: Adding Centralized Identity (SSO)

> **Format:** This is an *instructor walkthrough*, not a student lab. It is the
> story of a real architecture change — how single sign-on was added to the
> island, the decision that shaped it, and the exact files that changed. Walk
> the room through it on Day 3 as a worked example of evolving a live system.

## The Problem

By Day 3 the island has six tools — Gitea, ArgoCD, Harbor, Grafana, Rancher —
and **six separate logins**. Every student account had to be created six times.
Onboarding is six times the work; offboarding is six times the risk.

The goal: **one identity, defined once, in Git.** Add a student to a file, push,
and they exist everywhere. *Students as code.*

## How I Approached It — The Decision That Shaped Everything

My first instinct was **Ory Hydra**. It is an excellent, production-grade OAuth2
server. So I started there — and immediately hit the wall that defines this
whole design:

> **Hydra has no users.** It is a *token issuer*. By design it has no user
> database and no login screen — it delegates both to a separate identity
> service and a "login & consent" app you must build and run yourself.

So "add Hydra" was really "add Hydra **+** an identity store **+** a custom
login app." Three moving parts, and the one I cared about — the student
roster — was the part Hydra *didn't* provide.

I switched to **Dex**. Dex is the CNCF OIDC broker, and it has one feature that
makes it perfect here: a built-in password database (`staticPasswords`). The
roster lives **inside Dex's config file** — a plain, version-controllable file,
which is exactly the "students as code" we wanted.

!!! warning "Two files: a committed template and a gitignored live roster"
    The live roster — `k8s/core-tools/dex.yaml` — holds **real student names and
    emails (PII)**, so it is **gitignored**, exactly like `lab.env` and
    `students.csv`. What ships in Git is `dex.yaml.example`, a pirate-themed
    placeholder (a `test` user + a few pirates). Stand up SSO for a class with:

    ```bash
    cp k8s/core-tools/dex.yaml.example k8s/core-tools/dex.yaml
    # edit dex.yaml: swap the pirates for the real roster
    just deploy-dex
    ```

    "Roster as code" still holds — it's a file you edit, diff, and deploy. We
    just keep the copy with real identities out of the public repo.

**The lesson for the room:** picking infrastructure is not about which tool is
"best" in the abstract. Hydra is arguably the more powerful OAuth2 server. But
Dex *fit the shape of the problem* — a Git-defined roster — with far less to
build. Match the tool to the problem, not to the hype.

## The Architecture

```text
   students (browser)
        │  https://sso.{{ lab_domain }}
        ▼
   ┌─────────┐   reads roster from   ┌──────────────────────┐
   │   DEX   │◄──────────────────────│ dex.yaml (gitignored)│
   └────┬────┘   staticPasswords     │  = the student roster│
        │                           │ (template: .example) │
        │                           └──────────────────────┘
        │  OIDC tokens
        ▼
   Gitea · ArgoCD · Harbor · Grafana · Rancher
```

Dex is the single front door. Each app becomes an OAuth2 *client* of Dex. The
roster is one list in one file, version-controlled like everything else.

## Where The Changes Were Made

### 1. New files — `k8s/core-tools/dex.yaml.example` (committed) + `dex.yaml` (gitignored)

The whole identity service: a Deployment, a Service, an HTTPRoute for
`sso.{{ lab_domain }}`, and a ConfigMap holding two lists:

- **`staticPasswords`** — the roster. Each student is an entry with an email, a
  username, and a **bcrypt-hashed** password. *This is the students-as-code.*
- **`staticClients`** — one entry per app (Gitea, ArgoCD, Harbor, Grafana,
  Rancher), each with a client id, secret, and an exact redirect URI.

### 2. Declarative integrations — three Helm value files

Three apps accept OIDC config straight from their Helm values — pure GitOps, no
clicks:

| File | What was added |
| :--- | :--- |
| `k8s/core-tools/gitea-values.yaml` | a `gitea.oauth` entry — auto-registers the "Dex" login source |
| `k8s/core-tools/argocd-values.yaml` | `configs.cm.oidc.config` + `configs.rbac`; ArgoCD's own bundled Dex disabled |
| `k8s/core-tools/loki-stack-values.yaml` | Grafana `grafana.ini` `[auth.generic_oauth]` block |

Re-running `just deploy-gitea` / `deploy-argocd` / the Grafana install is all it
takes — the change is in Git, so it is reproducible forever.

### 3. The non-declarative integrations — Harbor and Rancher

Not every app plays nicely. This is the honest part of the walkthrough:

- **Harbor** — the Harbor Helm chart *cannot* set OIDC through `values.yaml`
  (a known chart limitation). OIDC is a **post-install API call**. The
  `just harbor-sso` recipe PUTs the config to `/api/v2.0/configurations`:

  ```bash
  curl -k -u "admin:AdmiralBashIsAwesome" -X PUT \
    https://harbor.{{ lab_domain }}/api/v2.0/configurations \
    -H "Content-Type: application/json" \
    -d '{
      "auth_mode": "oidc_auth",
      "oidc_name": "Dex",
      "oidc_endpoint": "https://sso.{{ lab_domain }}",
      "oidc_client_id": "harbor",
      "oidc_client_secret": "harbor-oidc-secret",
      "oidc_scope": "openid,profile,email,groups",
      "oidc_groups_claim": "groups",
      "oidc_auto_onboard": true,
      "oidc_user_claim": "name",
      "oidc_verify_cert": false
    }'
  ```

- **Rancher** — auth providers are not Helm-configurable either. Generic OIDC
  is enabled in the Rancher UI (*Users & Authentication → Auth Provider →
  Generic OIDC*) with client `rancher` / secret `rancher-oidc-secret` pointed at
  `https://sso.{{ lab_domain }}`. This is the one piece of "click-ops" in the
  whole stack.

**Teaching point:** in a real integration, tools fall into tiers — *pure
config* (Gitea, ArgoCD, Grafana), *API call* (Harbor), *manual UI* (Rancher).
Knowing which tier a tool is in **before** you start is what separates a
half-day of work from a surprise.

!!! tip "The same tiers show up again — wiring Mailpit"
    The stack ships a mock SMTP sink, **Mailpit** (<https://mailpit.{{ lab_domain }}>),
    so the apps can "send mail" with nowhere real for it to go. Pointing every
    app at it lands in the *exact same three tiers* as SSO did:

    - **Pure config** — Gitea (`mailer` block), Grafana (`grafana.ini [smtp]`),
      and ArgoCD (`notifications`) take it straight from their Helm values. Just
      (re)deploy; nothing else to do.
    - **API call** — Harbor has no mail values either, so `just harbor-mail`
      PUTs the SMTP settings to `/api/v2.0/configurations` — the same recipe
      shape as `harbor-sso`.
    - **Manual UI** — Rancher's SMTP notifier is added by hand (server
      `mailpit.admin-tools.svc.cluster.local`, port `1025`, no TLS, no auth).

    The SMTP endpoint is plain (no TLS, no auth) on `:1025`, and the in-cluster
    address is the Service FQDN above — Rancher lives in `cattle-system`, so the
    short `mailpit` name won't resolve from there. Same lesson, second time:
    know the tier **before** you start.

### 4. The TLS wrinkle

!!! note "Update — the cluster now serves a real certificate"
    This section describes the **original** self-signed-CA deployment. The
    production cluster now serves a real **Let's Encrypt** wildcard cert for
    `*.{{ lab_domain }}`, which browsers and tools trust natively — so the
    CA-mounting and skip-verify steps below are **no longer required** for a
    fresh deploy. The section is kept because the *lesson* still holds: a
    self-signed CA carries a real, cross-cutting cost. Understanding that cost
    is what makes "just use Let's Encrypt" an informed decision.

Dex serves its identity at `https://sso.{{ lab_domain }}`, secured by the
**self-signed lab CA**. Every app — and every app is a *client* of Dex — must
trust that CA to fetch Dex's discovery document, or the login silently fails.

How each app was handled:

- **Grafana / Harbor** — have a "skip TLS verify" flag (`tls_skip_verify_insecure`,
  `oidc_verify_cert: false`). Acceptable inside a closed cluster.
- **ArgoCD** — no skip flag, but `oidc.config` takes a `rootCA:` field — paste
  in `certs/ca.crt`.
- **Gitea** — no skip flag at all; the lab CA must be mounted into the Gitea
  container and trusted (`extraVolumeMounts` + `SSL_CERT_FILE`).

This is the cross-cutting cost of a self-signed CA: *every* client has to be
taught to trust it. Worth saying out loud to the faculty — that recurring cost
is precisely why the cluster later moved to a publicly-trusted Let's Encrypt
certificate.

### 5. Deploy recipe — `justfile`

A new `just deploy-dex` recipe applies `dex.yaml`. It uses a **restricted**
`envsubst '${LAB_DOMAIN}'` — a bare `envsubst` would mangle the `$` characters
inside the bcrypt password hashes. (A small bug, caught early — mention it; it
is a good reminder that `envsubst` substitutes *everything* by default.)

## The Payoff — Students As Code, Live

This is the demo to run for the room. It ties straight back to Day 3's GitOps
commandment, *Git is Truth*:

1. Open `k8s/core-tools/dex.yaml` (the live roster) — or `dex.yaml.example` if
   you're demoing from a fresh clone. Show the `staticPasswords` list — *"this
   is our entire roster."*
2. Add a new pirate. Generate the hash with `just dex-hash`, paste in a new
   entry.
3. Commit and push. `just deploy-dex`.
4. That new student can now log into **Gitea, ArgoCD, Harbor, Grafana, and
   Rancher** — all six tools — with one account that never existed five minutes
   ago.

> **🧑‍🏫 Instructor Superpower:** Onboarding is now a one-line pull request.
> Offboarding is deleting that line. Identity became code — reviewable,
> auditable, and diff-able like everything else on the island.

## Recap: The Files That Changed

```text
NEW   k8s/core-tools/dex.yaml.example      # Dex + a pirate placeholder roster (committed)
NEW   k8s/core-tools/dex.yaml              # the live roster — gitignored (real PII)
EDIT  k8s/core-tools/gitea-values.yaml     # oauth source
EDIT  k8s/core-tools/argocd-values.yaml    # oidc.config + rbac
EDIT  k8s/core-tools/loki-stack-values.yaml# Grafana generic_oauth
EDIT  k8s/core-tools/harbor-values.yaml    # documents the post-install API step
EDIT  k8s/rancher/rancher-values.yaml      # documents the UI step
EDIT  justfile                             # deploy-dex + dex-hash recipes
```

Six tools, one identity, one roster in Git. That is the switch — and now the
room has seen exactly how it was made.
