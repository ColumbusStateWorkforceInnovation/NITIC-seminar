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

1. Open `gitea.{{ lab_domain }}` in your browser and log in with the account the Admiral issued you.
2. Click **+ → New Repository**. Name it `island-stack`. Leave it **public** (the shipyard reads it anonymously) and create it.
3. Back on your client VM, go into the chart folder from Lab 01 and commit it:
   ```bash
   cd island-stack
   git init -b maindeck
   git add .
   git commit -m "Draft the island-stack blueprint"
   git remote add origin https://gitea.{{ lab_domain }}/<your-username>/island-stack.git
   git push -u origin maindeck
   ```
4. Refresh Gitea — your blueprint is now the official Captain's Log.

!!! note "Why `maindeck`?"
    On this island the trunk branch is `maindeck`, not `main`. Nautical
    trunk-based development — the whole crew commits to one deck.

## Step 2: Open the Shipyard (Create an ArgoCD Application)

1. Open `argocd.{{ lab_domain }}` and log in. (Your instructor will hand out the admin password, or you will get a personal account.)
2. Click **+ NEW APP** and fill in:
   - **Application Name:** `<your-name>-stack`
   - **Project:** `default`
   - **Sync Policy:** `Automatic` — tick **Prune Resources** and **Self Heal**
   - **Repository URL:** `http://gitea-http.admin-tools.svc.cluster.local:3000/<your-username>/island-stack.git`
   - **Revision:** `maindeck`
   - **Path:** `.`
   - **Cluster:** `https://kubernetes.default.svc`
   - **Namespace:** `<your-name>`
3. Click **CREATE**.

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
    namespace: blackbeard
  syncPolicy:
    automated:
      prune: true      # delete objects removed from Git
      selfHeal: true   # drag live state back to Git state
```

Watch the ArgoCD UI. Within seconds it reads your log, finds your Helm chart, and deploys the whole stack. The card turns green: **Healthy / Synced.**

## Step 3: The Mutiny (Drift Detection)

Now prove the shipyard actually fights for you.

1. On your client VM, manually scale a deployment *behind the shipyard's back*:
   `kubectl scale deployment <your-name>-cache --replicas=10 -n <your-name>`
2. Flip to the ArgoCD UI. The application card flips to **OutOfSync** — the shipyard sees the Crew's Actions (10 replicas) disagree with the Captain's Log (1 replica).
3. Because you enabled **Self Heal**, watch ArgoCD *mercilessly* scale you back down to 1 — the number written in Git. The mutiny is over.
4. Try again: `kubectl delete deployment <your-name>-cache -n <your-name>`. The shipyard rebuilds it from the log within seconds.

**Lesson learned:** You can no longer break your environment by fat-fingering `kubectl`. The only way to change the fleet is to change the log.

## 🧑‍🏫 Instructor Demo: The Live Classroom (JupyterLab via GitOps)

*Run this from the podium — it is the headline Instructor Superpower of the week.*

1. The instructor has an ArgoCD app watching a chart that deploys **JupyterLab**.
2. Edit the chart's `requirements.txt` — add a single line: `pandas`.
3. Commit and push to Gitea.
4. ArgoCD spots the change and re-syncs **every student's** Jupyter environment.
5. **The "Aha":** No student typed `pip install`. You distributed a heavy data-science library to the entire class by editing one file and pushing it. *You just shipped a lab over a URL.*

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
**🏆 Gamification Checkpoint:** First pirate whose ArgoCD app reaches **Healthy / Synced** *and* who can correctly explain the difference between the Captain's Log and the Crew's Actions wins a prize!
