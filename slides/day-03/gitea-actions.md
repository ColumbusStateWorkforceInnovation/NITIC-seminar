---
marp: true
auto-scaling: false
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 3 · Gitea Actions"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 3 · Opening Demo · 30 minutes

# Gitea Actions

## In-cluster CI, GitHub-Actions-compatible

*Before we template the manifests (Helm) and before we deploy them (ArgoCD), there is a question we have been quietly skipping: where does the image come from?*

<!-- Day 3 opens here. The deck used to live at 4:15 PM, after ArgoCD was taught. It now opens the day, BEFORE Helm and ArgoCD. The framing change: this is the "build half" of the CI/CD loop. The "CD half" is the afternoon. Time-box this hard — 30 minutes total, demo only, no student keyboards. -->

---

## Where does the image come from?

- For two days, *we* built the images — locally, with `docker build`, then `docker push` to Harbor.
- That isn't a workflow. That's the instructor cheating off-stage.
- After lunch you'll meet **ArgoCD**, which pulls images from Harbor and ships them to the cluster. But ArgoCD assumes the image is **already there**.
- This morning we fix that: a `git push` automatically produces a tagged image in Harbor, with no human in the middle.

> *Today we build the build half. After lunch ArgoCD finishes the loop.*

<!-- This is the honest acknowledgement — the lab so far has hand-built images. Today's demo plugs the build half. The deploy half ("ArgoCD pulls this") is foreshadowed and lands in the afternoon. -->


---

## The committed shape (and what we actually built)

- The original course outline named **GitHub Actions**: workflows, jobs, secrets, build-and-push.
- We will **not** use GitHub Actions in the cluster. The room has no public internet path and the cluster shouldn't depend on github.com.
- Instead: **Gitea Actions** — the same workflow YAML, executed by an in-cluster runner against our in-cluster Gitea.
- *Same mental model. Different home.*

| Concept | GitHub Actions | Gitea Actions |
| :--- | :--- | :--- |
| Workflow file | `.github/workflows/ci.yaml` | `.gitea/workflows/ci.yaml` |
| Runner | GitHub-hosted or self-hosted | `act_runner` pod in our cluster |
| Image cache | github.com Actions cache | local registry / runner volume |
| Marketplace | `uses: docker/build-push-action@v5` | **same** — Gitea Actions is `act`-compatible |

<!-- Land that the YAML is literally identical. A student who learns this here can copy it into a github.com repo on Monday and it still works. That is the abstract-commitment payoff. -->

---

## What's actually running
<!-- _class: diagram-sm -->

```text
  ┌──────────────────┐    push     ┌──────────────────┐
  │  Student VM      │ ──────────► │  Gitea           │
  │  git push        │             │  (in-cluster)    │
  └──────────────────┘             └────────┬─────────┘
                                            │ webhook
                                            ▼
                                  ┌──────────────────┐
                                  │  act_runner pod  │  ← reads .gitea/workflows/ci.yaml
                                  │  (in-cluster)    │     runs build steps in a container
                                  └────────┬─────────┘
                                            │ docker push
                                            ▼
                                  ┌──────────────────┐
                                  │  Harbor          │  ← image lands here. This afternoon,
                                  │  (in-cluster)    │     ArgoCD picks it up from here.
                                  └──────────────────┘
```

*Every box on this diagram is a pod in your cluster.*

<!-- Walk the arrows. The big "aha" is that there are no off-cluster dependencies — push triggers webhook triggers runner triggers registry. The ArgoCD arrow is foreshadowed but not yet drawn — the room will see it close in the afternoon. -->


---

## The workflow file
<!-- _class: code-tiny -->

```yaml
# .gitea/workflows/ci.yaml
name: build-and-push
on:
  push: { branches: [main] }
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Log in to Harbor
        uses: docker/login-action@v3
        with:
          registry: harbor.${{ vars.LAB_DOMAIN }}
          username: ${{ secrets.HARBOR_ROBOT_USER }}
          password: ${{ secrets.HARBOR_ROBOT_SECRET }}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: harbor.${{ vars.LAB_DOMAIN }}/raft-fleet/raft:${{ github.sha }}
```

*That's it. Same syntax a working Actions engineer writes on day one.*

<!-- This slide is the deliverable. The workflow file is real, lives in docs/missions/day-03/gitea-actions-demo/, and runs against our cluster. Project it side by side with a real GitHub Actions file from your laptop after the live demo. -->

---

## Live demo — push to image

We're going to push a one-character change to a repo and watch it
produce a tagged image in Harbor, with no human in the middle.

1. **Edit** a string in the `raft` repo's `index.html`.
2. **Commit + push** to Gitea.
3. Watch the **Actions** tab in Gitea — runner picks up the job within 5 seconds.
4. Watch the build logs stream in real time.
5. Watch **Harbor** — a new tag appears under `raft-fleet/raft` when push completes.

*From `git push` to tagged image in under 60 seconds. The image is now sitting in Harbor, waiting for something to deploy it.*

<!-- This is the build half of the demo. If something breaks, bail to the recording. After lunch (after the ArgoCD lab), the instructor can callback: "remember this morning's tag in Harbor? Watch ArgoCD pick it up." That closes the loop for real. -->


---

<!-- _class: chapter -->

#### What's next on the shelf

# Beyond Gitea Actions

```text
   ~~~^~~~~~^~~~~~~^~~~~^~~~~~^~~~
  ~~~~~~^~~~~~~^~~~~^~~~~~~^~~~~~~~
   ~^~~~~~^~~~~~~^~~~~~^~~~~~^~~~~~
```

---

## When Gitea Actions stops being enough

- **Gitea Actions** is the right answer for: classroom labs, small teams, GitHub-compatible workflows.
- It's the *wrong* answer when you need:
  - DAG topologies (fan-out / fan-in across many steps with conditional dependencies)
  - **CRD-native** pipelines that other Kubernetes tools can introspect
  - First-class CNCF graduation status for your platform's compliance review

*Two CNCF-graduated projects exist for exactly that.*

<!-- This is the "you'll grow out of this" slide. Be honest — Gitea Actions covers 90% of academic and small-team use. The other two slides exist so faculty know the words their students will hear in industry. -->

---

## Argo Workflows — the Argo family answer
<!-- _class: code-sm -->

- **CNCF graduated.** Same project family as ArgoCD.
- Pipelines are CRDs — `Workflow`, `WorkflowTemplate`, `CronWorkflow`.
- Designed around **DAGs** — every step is a container, dependencies are explicit.
- Argo **Events** (sibling project) gives you webhook / git / S3 / kafka triggers.
- Most natural fit if you're already standing up ArgoCD — same UI conventions, same RBAC story.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
spec:
  templates:
    - name: build
      container: { image: gcr.io/kaniko-project/executor, args: [...] }
```

<!-- One slide. Don't deep-dive. The point is: "if you outgrow Gitea Actions and you already love Argo, this is the obvious next step." -->

---

## Tekton — the industry-standard answer
<!-- _class: code-sm -->

- **CNCF graduated.** The reference Kubernetes-native CI engine.
- Pipelines are CRDs — `Task`, `Pipeline`, `PipelineRun`, `TaskRun`.
- 1:1 conceptual map to GitHub Actions: workflow → pipeline, job → task, step → step.
- **Tekton Hub** is a large catalog of reusable Tasks (build, scan, sign, deploy).
- The one you'll see in industry CI/CD platforms (OpenShift Pipelines is Tekton, Jenkins X uses Tekton, etc.).

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
spec:
  tasks:
    - name: build-image
      taskRef: { name: buildah, kind: ClusterTask }
```

<!-- The "you should know this exists" slide. Faculty whose students will go work at large enterprises will see Tekton in production. -->

---

## How to choose, in one sentence

| If you want… | Reach for… |
| :--- | :--- |
| GitHub Actions semantics, in-cluster, today | **Gitea Actions** |
| DAGs in the same UI as your ArgoCD | **Argo Workflows** |
| CNCF reference platform, big task catalog | **Tekton** |

*All three run on the same cluster you already have. None of them is wrong.*

<!-- This is the slide you leave on screen during Q&A. It is the decision matrix. -->

---

<!-- _class: lead -->
<!-- _footer: "" -->

## Now: meet Hazel.

*You've seen the build half. The template + deploy halves are the rest of today.*

<!-- Hand off to the Helm lecture. The "close the loop with ArgoCD" moment is foreshadowed for the afternoon — when ArgoCD ships an image they watched build at 09:00, the loop lands hard. -->
