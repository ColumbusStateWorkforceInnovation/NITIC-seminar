# Lab 01: The Pirate Strikes!

The theory lecture is over. Something is wrong.

Pods in your namespace are dying and respawning. Your 3-tier app flickers — the frontend loads, then 502s, then loads again. A **Pirate** has boarded the cluster: he ran an active Chaos Engineering attack against the whole fleet **and** force-pushed a sabotaged, fragile version of your `island-stack` chart onto your `maindeck` branch. ArgoCD dutifully deployed his sabotage. Your fleet is now brittle *and* under fire.

This is the Admiral's Challenge. Everything you have learned this week — `k9s`, logs, events, Services, NetworkPolicies, GitOps, Gitea Actions — you need all of it now.

## ⚓ The Two Deliverables (this is graded)

You succeed when you produce **both** of:

1. **A cluster that holds.** Your 3-tier pipeline serves traffic reliably for 60 straight seconds while the attack is still running. An instructor-run grading script ([`scripts/grade-cluster-recovery.sh`](../../../scripts/grade-cluster-recovery.sh)) confirms this end-to-end.
2. **A Salvage Report.** A written incident report (markdown) using the [template provided](incident-report-template.md), covering root cause, the timeline of what you tried, the commands that fixed it, and one prevention recommendation. The **Incident Commander** AI persona — which your instructor will switch on **mid-lab** when packet loss is peak-painful — drafts most of this for you. Your job is to verify, edit, and own it.

**Both pieces submit by 12:00 sharp** (before lunch). Both are scored against the rubric in `incident-report-template.md`.

## 🧑‍🏫 Instructor Superpower: Chaos as the Exam

*A `NetworkChaos` manifest is a better exam than any multiple-choice test. It does not ask students what they know — it forces them to prove they can auto-remediate a live incident. Grade the recovery, grade the report. Both together demonstrate transferable skill in a way a written test cannot.*

## ⚓ The Rules of Engagement

- You **cannot** delete the Pirate's attack — you do not own the `chaos` namespace.
- You **can** harden your own namespace, lean on the automation you built, and ship fixes through Gitea Actions.
- Work as your Day 2/3 alliance. Communicate across your three tiers.
- The capstone runs **105 minutes (10:15 – 12:00)**. **Submit both deliverables by 12:00 sharp** — before lunch. There is no afternoon drafting block; the last ~30 minutes of the lab is for drafting with the Incident Commander.

## Step 1: Assess the Damage

Do not panic-delete anything yet. First, *observe*.

1. Open `k9s`. Watch your namespace. What is the pattern — are pods dying *randomly*, or all at once? Are they coming *back*?
2. Pull the cluster's event stream — events are the ship's incident report:
   ```bash
   kubectl get events -n <your-name> --sort-by=.lastTimestamp
   ```
3. Test your pipeline. From the frontend tier, try to reach the backend repeatedly. Does it fail *every* time, or *intermittently*? Intermittent failure is a clue — that is packet loss, not a hard outage.

**Salvage Report → § Timeline:** start the clock. Note what you observe and what time you observed it.

## Step 2: Name the Saboteur

Random pod deaths and intermittent packet loss do not happen by themselves. Something is *causing* them.

1. Remember this morning's lecture — **Chaos Mesh**. Chaos experiments are just Kubernetes objects. Go look for them — the recurring attacks are driven by `Schedule` objects:
   ```bash
   kubectl get schedule,podchaos,stresschaos -A
   ```
2. You will find experiments living in the `chaos` namespace. Describe one:
   ```bash
   kubectl describe schedule kraken-pod-failure-<your-namespace> -n chaos
   ```
3. Read its `selector`. *That* is how the Pirate is targeting you. Now you know your enemy.

**Salvage Report → § Root Cause:** name the attack(s) and write down which selector targets your namespace.

## Step 3: Diagnose the Sabotage

Here is the first thing to notice: **you are *not* surviving — and that is the Pirate's doing.**

On Day 3 you hardened nothing because nothing was attacking you. The Pirate just force-pushed a **fragile** `island-stack` over your work, and ArgoCD deployed it. Go read what he changed:

1. Look at what is actually running, and why it folds:
   ```bash
   kubectl get deploy -n <your-namespace>        # every tier is at replicas: 1
   kubectl describe deploy <name>-frontend -n <your-namespace>   # no readinessProbe; CPU limit pinned to 50m
   ```
2. Now open your **own repo** — the sabotage is in `values.yaml` on `maindeck`. Three deliberate weaknesses are called out in the comments at the top of that file:
   - **`replicaCount: 1`** — one pod-kill takes the whole tier down until it respawns.
   - **`readinessProbe.enabled: false`** — a pod broken by `pod-failure` keeps taking traffic, so you serve 502s.
   - **`resources.limits.cpu` too tight** — if the Pirate adds CPU stress, the app starves.
3. **Lesson:** resilient architecture is a set of deliberate choices — replicas, health probes, resource budgets. The Pirate stripped them. Your job is to put them back.

**Salvage Report → § Recovery Steps:** the first entry is *"identified the sabotaged fragile baseline on `maindeck` — 1 replica, no readiness probe, tight CPU limit."*

## Step 4: Re-Harden Your Fleet (GitOps Under Fire)

You fix this the way you ship everything this week: **edit your repo, push, let ArgoCD sync.** No `kubectl edit` band-aids — the Pirate's self-heal will just revert those. The only durable fix is a commit.

1. In your `island-stack` repo, edit **`values.yaml`** to undo the sabotage. Start with the **`frontend`** tier (that is the one the grading script measures), then backend/cache as your CPU budget allows:
   ```yaml
   frontend:
     replicaCount: 2                 # survive pod-kill — a survivor keeps serving
     readinessProbe:
       enabled: true                 # drop pods broken by pod-failure out of the Service
     resources:
       limits:
         cpu: "100m"                 # right-size so CPU stress can't starve it
   ```
2. Commit and push to `maindeck`:
   ```bash
   git commit -am "harden: replicas + readiness + cpu on the fleet"
   git push
   ```
3. Open ArgoCD (`argocd.{{ lab_domain }}`) and watch your app flip **OutOfSync → Synced** as it rolls your hardened fleet out — *while the attack is still running.*
   > **It won't react instantly.** ArgoCD polls Git on a timer (up to ~3 min). Don't think your push failed — hit **Refresh** (or **Sync**) on your app in the ArgoCD UI to pull the new commit immediately.
4. **Mind the quota.** Your namespace caps at ~500m CPU (≈5 small pods). Harden the graded `frontend` first; only scale backend/cache up if you have budget, or pods sit **Pending**.
5. **Optional stretch (Gitea Actions):** if a tier needs a real image fix, push it through Day 3's Gitea Actions pipeline. Shipping under attack is the real-world story.

**Salvage Report → § Recovery Steps:** the second entry is the hardening diff. Paste the `values.yaml` change you committed.

## Step 5: Stabilize and Submit

You succeed when your 3-tier pipeline serves traffic **reliably** for 60 straight seconds while the attack is still running, **and** the grading script signs off.

1. Hammer your frontend in a loop and confirm clean responses (in-cluster Service DNS — run it from a `kubectl run` shell or a pod in your namespace):
   ```bash
   while true; do curl -s -o /dev/null -w "%{http_code}\n" http://<your-name>-frontend.<your-namespace>.svc.cluster.local; sleep 1; done
   ```
2. When it holds steady, call your instructor. They will run:
   ```bash
   just grade <your-name>
   ```
   Pass = your alliance has cleared the cluster-recovery gate.
3. **Hand in the Salvage Report by 12:00 sharp.** Use the template at [`incident-report-template.md`](incident-report-template.md). The Incident Commander AI persona — switched on by your instructor mid-lab — will draft most of it from your `k9s` logs. Your job is to verify, fill in § 5 (Prevention), and submit before lunch.

---

## 📋 Instructor Playbook (do not project — instructor eyes only)

The whole attack is automated — no hand-edited YAML. During the **10:10 break**, run, in order:

```bash
just deploy-chaos-mesh    # once — installs the attack platform, creates the `chaos` ns
just normalize-repos      # Pirate force-pushes the FRAGILE island-stack to every crew's maindeck
just chaos-strike         # recurring pod-kill + pod-failure on every student namespace
```

`normalize-repos` resets the whole cohort to one identical fragile baseline (1 replica, readiness off, tight CPU limit) and ensures every crew has a self-healing `<crew>-stack` ArgoCD Application — so grading is deterministic and nobody is stuck without an app to harden. The attacks are Chaos Mesh **Schedules**, so they recur until you stop them.

> **Tip:** run `just clear-decks` *before* `normalize-repos` if Day-3 leftovers are eating namespace quota — the fragile stack needs room to deploy.

**Confirm it's live:** `just chaos-status` shows the `kraken-pod-kill-*` and `kraken-pod-failure-*` Schedules `Running`; pods in student namespaces start cycling.

**Kill switch (room melts down, or at 12:00 to end the game):**
```bash
just chaos-calm           # deletes every Schedule + chaos object cluster-wide
```

### The chaos mix

Each attack exposes one deliberate weakness in the sabotaged chart, and each has exactly one fix the crew makes in **`values.yaml`** → `git push` → ArgoCD syncs:

| Attack (`just chaos-strike`) | Weakness it exposes | The fix (edit `values.yaml`) |
| :--- | :--- | :--- |
| `PodChaos` pod-kill, recurring | `replicaCount: 1` — kill the only pod, the tier is down | raise replicas (frontend first) |
| `PodChaos` pod-failure, recurring | `readinessProbe.enabled: false` — a broken pod keeps serving 502s | enable the readiness probe |

**Optional escalation** — `just chaos-stress [namespace]` (no arg = all crews; pass a name for one):

| Attack | When to release | The fix |
| :--- | :--- | :--- |
| `StressChaos` CPU saturation | Drop on a team that grade-passed early and is bored, or to push a team harder. | Right-size `resources.limits.cpu` (Day 2 taught this). |

The AI is in-bounds — students use the Incident Commander to read events and draft the `values.yaml` diff. That's the design, not cheating.

### Running the grading script

Once a team says they're stable, run (zero-config — it derives the names from the namespace, and runs on the server so it hits the real cluster):
```bash
just grade <crew>     # e.g. just grade blackbeard
```
The script (see `scripts/grade-cluster-recovery.sh`) verifies every Pod in the namespace is Ready (Gate 1), runs a 60-second curl loop against the crew's `<crew>-frontend` Service needing ≥95% 2xx (Gate 2), and verifies their `<crew>-stack` ArgoCD Application reports `Synced + Healthy` (Gate 3). It exits 0 on pass, non-zero on fail, and prints a structured summary you can paste into the team's report. (Tip: run it against a namespace mid-attack *before* the team hardens — it should FAIL Gate 2 — to calibrate.)

### Grading the Salvage Reports

Grading is structurally a rubric (in `incident-report-template.md`) but in practice this is a **checkbox exercise** — alliances that turn in a complete report with the grading script PASS should expect a 100. The rubric exists to scaffold the report-writing for students who care about the structure, not to differentiate between teams. If a report is conspicuously thin in § 5 (Prevention) or the grading script never passed, that's the only reason to mark down.
