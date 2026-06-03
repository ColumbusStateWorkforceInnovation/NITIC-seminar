# Lab 02: The Automated Shipyard

You have a blueprint (your Helm chart). But you are still launching ships by hand — `helm install`, `helm upgrade`, over and over. That is not a shipyard. That is you, with a hammer.

A real **Automated Shipyard** runs itself. You write the orders down in the **Captain's Log** (a Git repository). The shipyard (**ArgoCD**) reads the log, and builds the fleet to match — automatically, forever. If a ship drifts off course, the shipyard hauls it back.

This is **GitOps**, and its one commandment is: **Git is Truth.**

## 🧠 The Mental Model

| Nautical | Kubernetes | What it means |
| :--- | :--- | :--- |
| The Captain's Log | Your Git repo | **Desired state** — what you *wrote down* |
| The Crew's Actions | The live cluster | **Live state** — what is *actually running* |
| The Shipyard | ArgoCD | The engine that makes Live match Desired |

ArgoCD has exactly one job: notice when the Crew's Actions disagree with the Captain's Log, and fix it.

## Step 1: Commit the Log (Push Your Chart to Gitea)

The island has its own private Git server — **Gitea** — so nothing ever has to leave the cluster.

1. Open `gitea.{{ lab_domain }}` in your browser and log in with the account the Admiral issued you (the same island single-sign-on you've used all week).
2. Click **+ → New Repository**. Name it `island-stack`. Leave it **public** (the shipyard reads it anonymously) and create it.
3. **Mint a push token.** Because you sign in to Gitea through single-sign-on, your account has **no Git password** — so an HTTPS `git push` has nothing to authenticate with. Create a Personal Access Token to use as your password instead:
    - Click your avatar (top-right) → **Settings → Applications**.
    - Under **Manage Access Tokens**, name it (e.g. `client-vm`), expand **Select permissions**, and set **`repository` → Read and Write**.
    - Click **Generate Token** and **copy it now** — Gitea shows it only once. This string *is* your push password.
4. Back on your client VM, go into the chart folder from Lab 01 and commit it:
   ```bash
   cd island-stack
   git init -b maindeck
   git add .
   git commit -m "Draft the island-stack blueprint"
   git remote add origin https://gitea.{{ lab_domain }}/<name>/island-stack.git
   git push -u origin maindeck
   ```
   When `git push` prompts you, enter your **Gitea username** and paste the **token** as the password (not your SSO password — there isn't one).
5. Refresh Gitea — your blueprint is now the official Captain's Log.

!!! note "Why `maindeck`?"
    On this island the trunk branch is `maindeck`, not `main`. Nautical
    trunk-based development — the whole crew commits to one deck.

## Step 2: Open the Shipyard (Create an ArgoCD Application)

!!! warning "Scrap your manual release first"
    In Lab 01 you ran `helm install my-stack`. The shipyard is about to manage
    the **same** ships in the **same** namespace — and two captains fighting over
    one fleet means name collisions and double the pods (your namespace has a
    small CPU budget). Hand the helm over cleanly first:
    ```bash
    helm uninstall my-stack -n student-<name>
    ```
    From here on, the **only** way you launch ships is through Git.

1. Open `argocd.{{ lab_domain }}` and log in **as the `admin` account** — your instructor will read out the password. Everyone uses the same `admin` login today: the per-person SSO logins are **read-only** (they can watch apps but can't create them), so `admin` is how you create an Application.
2. Click **+ NEW APP** and fill in:
   - **Application Name:** `<name>-stack`
   - **Project:** `default`
   - **Sync Policy:** `Automatic` — tick **Prune Resources** and **Self Heal**
   - **Repository URL:** `http://gitea-http.admin-tools.svc.cluster.local:3000/<name>/island-stack.git`
   - **Revision:** `maindeck`
   - **Path:** `.`
   - **Cluster:** `https://kubernetes.default.svc`
   - **Namespace:** `student-<name>`
3. Click **CREATE**.

!!! note "Two URLs — don't swap them"
    You `git push`ed to **`https://gitea.{{ lab_domain }}/...`** (the front door,
    from your client VM). But ArgoCD reads the repo from *inside* the cluster, so
    its **Repository URL** is the internal address
    **`http://gitea-http.admin-tools.svc.cluster.local:3000/...`** — `http`, not
    `https`, and a `.svc.cluster.local` host. Paste the **internal** one into the
    form. If ArgoCD says *"failed to resolve"* or *"repository not found"*, this
    is almost always the URL (or a repo you left **private** — it must be public).

That form just wrote an `Application` object. This is what it looks like as YAML — the shipyard is itself just Kubernetes:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: blackbeard-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea-http.admin-tools.svc.cluster.local:3000/blackbeard/island-stack.git
    targetRevision: maindeck
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: student-blackbeard
  syncPolicy:
    automated:
      prune: true      # delete objects removed from Git
      selfHeal: true   # drag live state back to Git state
```

Watch the ArgoCD UI. Within seconds it reads your log, finds your Helm chart, and deploys the whole stack. The card turns green: **Healthy / Synced.**

## Step 3: The Mutiny (Drift Detection)

Now prove the shipyard actually fights for you.

1. On your client VM, manually scale a deployment *behind the shipyard's back*:
   `kubectl scale deployment <name>-cache --replicas=10 -n student-<name>`
2. Flip to the ArgoCD UI. The application card flips to **OutOfSync** — the shipyard sees the Crew's Actions (10 replicas) disagree with the Captain's Log (1 replica).
3. Because you enabled **Self Heal**, watch ArgoCD *mercilessly* scale you back down to 1 — the number written in Git. The mutiny is over.
4. Try again: `kubectl delete deployment <name>-cache -n student-<name>`. The shipyard rebuilds it from the log within seconds.

**Lesson learned:** You can no longer break your environment by fat-fingering `kubectl`. The only way to change the fleet is to change the log.

## Step 4: Raid a Neighbor (Collaborative Sabotage)

You've proven the shipyard fights for *you*. Now prove it fights for **everyone** — by attacking someone else's fleet.

The Admiral has granted you boarding rights across the cohort. Pick a crewmate whose app is **Healthy / Synced**, and try to sink it:

1. Delete one of *their* deployments:
   `kubectl delete deployment <their-name>-cache -n student-<their-name>`
2. Watch **their** ArgoCD card flip to **OutOfSync** — then heal right back. Their Captain's Log won. You cannot board a ship whose log you don't hold.
3. Try scaling it, patching the image, deleting a Service — *anything* live. It all heals away. Live edits are **graffiti.**

!!! warning "One action in the UI does NOT heal — don't touch app cards"
    Everything above heals because the **Application** still exists — ArgoCD keeps
    reconciling it. The one thing that does **not** heal is deleting the
    **Application itself** (its card in the ArgoCD UI). Because the whole room is on
    the shared **`admin`** login today, you *can* click **Delete** on a neighbour's
    card — **don't.** With **Prune** on, deleting an Application tears down its
    entire stack, and it will **not** come back on its own — someone has to recreate
    the app. **Rule of thumb: raid with `kubectl` on a *deployment* (it heals);
    never click Delete on an *Application* card — yours or anyone else's.**

> ### So how *do* you change a crewmate's fleet?
> You don't touch their cluster — you change their **law.** Open a **pull request**
> against their Gitea repo (a healthcheck, an extra replica, a fixed label). When
> *they* merge it, ArgoCD ships it, and it **sticks.** That is the only raid that lasts.

**Lesson learned:** `kubectl` is a suggestion; **Git is the law.** Broad rights are safe *because* every fleet self-heals to its log — the only durable way to change anything is through a commit someone accepted.

!!! note "Instructor setup — broadened rights required"
    Step 4 only works if students have been granted rights to reach across the
    cohort: cluster-wide **read** (already granted by `just grant-explorer`) plus
    **delete/patch** on the other student namespaces. Run **`just grant-raider`**
    before class — it binds delete/patch on Deployments + Services into every
    `student-<name>` namespace (never the admin namespaces, never secrets). This
    is **not** the default per-namespace confinement; it is a deliberate, scoped
    grant for this lab, and it's safe **because** every fleet self-heals — keep
    **Self-Heal on** for every student `Application`. Tear it down afterward with
    `just revoke-raider`. If you skip the grant, run Step 4 as a paired demo (two
    volunteers, one screen) instead.

## 🏁 Stretch Goal: Close the CI Loop (Gitea Actions)

GitOps handled *deployment*. Can you automate the *build* too? Gitea has a built-in CI engine (**Gitea Actions**, GitHub-Actions-compatible).

Add `.gitea/workflows/build.yaml` to your repo:

{% raw %}
```yaml
name: Build the Raft
on:
  push:
    branches: [maindeck]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build & push image to Harbor
        run: |
          echo "Building ${{ github.repository }}..."
          # docker build + docker push to harbor.${LAB_DOMAIN}
```
{% endraw %}

Push it, then watch the **Actions** tab in Gitea light up.

!!! warning "Needs a runner"
    Gitea Actions only runs if your instructor has registered an **Actions
    runner** in the cluster. If the Actions tab shows your job stuck on
    *"waiting"*, the runner is not deployed yet — flag it and move on; the
    GitOps loop above is the part that matters today.

---
**Done when:** your ArgoCD app shows **Healthy / Synced** *and* you can articulate the difference between the Captain's Log (the desired state in Git) and the Crew's Actions (what the controller is actually doing on the cluster).
