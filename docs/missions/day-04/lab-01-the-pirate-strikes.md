# Lab 01: The Pirate Strikes!

The theory lecture is over. Something is wrong.

Pods in your namespace are dying and respawning. Your 3-tier app flickers — the frontend loads, then 502s, then loads again. A **Pirate** has boarded the cluster and is running an active Chaos Engineering attack against the whole fleet.

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

1. Remember this morning's lecture — **Chaos Mesh**. Chaos experiments are just Kubernetes objects. Go look for them:
   ```bash
   kubectl get podchaos,networkchaos -A
   ```
2. You will find experiments living in the `chaos` namespace. Describe one:
   ```bash
   kubectl describe networkchaos <name> -n chaos
   ```
3. Read its `selector`. *That* is how the Pirate is targeting you. Now you know your enemy.

**Salvage Report → § Root Cause:** name the attack(s) and write down which selector targets your namespace.

## Step 3: The Fleet Fights Back (GitOps Self-Heal)

Here is the first thing to notice: **you are already surviving.**

The Pirate keeps killing your pods — but your Day 2 **Deployments** respawn them, and your Day 3 **ArgoCD** self-heal drags every change back to the Captain's Log. The automation you built earlier this week is, right now, fighting the Pirate for you without you typing a thing.

1. Open ArgoCD (`argocd.{{ lab_domain }}`). Watch it flip **OutOfSync → Synced** over and over as it heals the pod-kills.
2. **Lesson:** resilient architecture is not about *preventing* failure. It is about *recovering* from it automatically.

**Salvage Report → § Recovery Steps:** the first entry is *"observed automatic self-heal via Deployments + ArgoCD."* That counts. Write it down.

## Step 4: Raise the Blockade (Defend Your Namespace)

Pod-kills you can survive. The `NetworkChaos` packet loss is harder — you must harden your borders.

1. Ask your AI (the **Boatswain** is still on duty until your instructor calls the persona shift to **Incident Commander** mid-lab — see the side-quest in `day-04-admirals-challenge.md`): *"How do I write a NetworkPolicy that only allows ingress from my alliance's namespaces and denies everything else?"*
2. Each tier writes a `NetworkPolicy` that admits traffic **only** from its alliance partners — and nothing else. A tightly scoped allow-list gives the Pirate's agent far less room to operate.
3. Apply it the GitOps way — commit it to your repo and let ArgoCD ship it. Stay disciplined even under fire.
4. **Optional stretch (Gitea Actions):** if your tier's app has a bug the chaos exposed, push the fix through Day 3's Gitea Actions pipeline. Shipping under attack is the real-world story.

**Salvage Report → § Recovery Steps:** the second entry is the NetworkPolicy. Paste the YAML you committed.

## Step 5: Stabilize and Submit

You succeed when your 3-tier pipeline serves traffic **reliably** for 60 straight seconds while the attack is still running, **and** the grading script signs off.

1. Hammer your frontend in a loop and confirm clean responses:
   ```bash
   while true; do curl -s -o /dev/null -w "%{http_code}\n" http://<frontend-svc>; sleep 1; done
   ```
2. When it holds steady, call your instructor. They will run:
   ```bash
   ./scripts/grade-cluster-recovery.sh <your-namespace>
   ```
   Pass = your alliance has cleared the cluster-recovery gate.
3. **Hand in the Salvage Report by 12:00 sharp.** Use the template at [`incident-report-template.md`](incident-report-template.md). The Incident Commander AI persona — switched on by your instructor mid-lab — will draft most of it from your `k9s` logs. Your job is to verify, fill in § 5 (Prevention), and submit before lunch.

---

## 📋 Instructor Playbook (do not project — instructor eyes only)

Install Chaos Mesh during the 10:30 break (it is **not** in `deploy-core` — install from `k8s/core-tools/chaos-mesh-values.yaml`). Create a `chaos` namespace, then apply the two experiments below. **Edit the `namespaces:` selectors to match your real student roster namespaces** before applying.

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: kraken-pod-kill
  namespace: chaos
spec:
  action: pod-kill
  mode: one
  duration: "90m"
  selector:
    namespaces: ["blackbeard", "annebonny", "calicojack"]
---
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: kraken-packet-loss
  namespace: chaos
spec:
  action: loss
  mode: all
  duration: "90m"
  direction: both
  loss:
    loss: "40"
    correlation: "25"
  selector:
    namespaces: ["blackbeard", "annebonny", "calicojack"]
```

**Emergency stop** (if the room melts down): `kubectl delete podchaos,networkchaos --all -A`

### The chaos mix

**Two main attacks (apply during the 10:30 break, target all student namespaces):**

| Attack | What it does | What fixes it |
| :--- | :--- | :--- |
| `PodChaos` action: pod-kill, mode: one | Randomly deletes one pod every ~30s | Nothing — Deployments + ArgoCD self-heal. Teaches resilience by observation. |
| `NetworkChaos` action: loss, 40%, both directions | Drops 40% of packets in/out of student namespaces | A NetworkPolicy admitting only alliance partners. This is the actual graded recovery. |

**One optional targeted attack (release at your discretion):**

| Attack | When to release | What fixes it |
| :--- | :--- | :--- |
| `StressChaos` CPU saturation, single namespace | Drop on a specific team that grade-passed early and is bored, or on a team you want to push harder. Released ad-hoc, not at the start. | Resource limits on the affected Deployment (Day 2 taught this). |

**Kill switch (room melts down):** `kubectl delete podchaos,networkchaos,stresschaos --all -A`

The AI is in-bounds — students will use the Incident Commander to draft NetworkPolicy syntax and read events. That's the design, not cheating.

### Running the grading script

Once a team says they're stable, run:
```bash
./scripts/grade-cluster-recovery.sh <namespace>
```
The script (see `scripts/grade-cluster-recovery.sh`) runs a 60-second curl loop against the frontend, verifies every Pod in the namespace is Ready, and verifies the team's ArgoCD Application reports `Synced + Healthy`. It exits 0 on pass, non-zero on fail, and prints a structured summary you can paste into the team's report.

### Grading the Salvage Reports

Grading is structurally a rubric (in `incident-report-template.md`) but in practice this is a **checkbox exercise** — alliances that turn in a complete report with the grading script PASS should expect a 100. The rubric exists to scaffold the report-writing for students who care about the structure, not to differentiate between teams. If a report is conspicuously thin in § 5 (Prevention) or the grading script never passed, that's the only reason to mark down.
