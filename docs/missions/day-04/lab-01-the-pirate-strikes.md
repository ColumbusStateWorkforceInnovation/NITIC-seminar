# Lab 01: The Pirate Strikes!

The theory lecture is over. Something is wrong.

Pods in your namespace are dying and respawning. Your 3-tier app flickers — the frontend loads, then 502s, then loads again. A **Pirate** has boarded the cluster and is running an active Chaos Engineering attack against the whole fleet.

This is the Admiral's Challenge. Everything you have learned this week — `k9s`, logs, events, Services, NetworkPolicies, GitOps — you need all of it now. **Be the first alliance to trace the root cause and stabilize your logistics pipeline.**

## 🧑‍🏫 Instructor Superpower: Chaos as the Exam

*A `NetworkChaos` manifest is a better exam than any multiple-choice test. It does not ask students what they know — it forces them to prove they can auto-remediate a live incident. Grade the recovery, not the recall.*

## ⚓ The Rules of Engagement

- You **cannot** delete the Pirate's attack — you do not own the `chaos` namespace.
- You **can** harden your own namespace and lean on the automation you built.
- Work as your Day 2/3 alliance. Communicate across your three tiers.

## Step 1: Assess the Damage

Do not panic-delete anything yet. First, *observe*.

1. Open `k9s`. Watch your namespace. What is the pattern — are pods dying *randomly*, or all at once? Are they coming *back*?
2. Pull the cluster's event stream — events are the ship's incident report:
   ```bash
   kubectl get events -n <your-name> --sort-by=.lastTimestamp
   ```
3. Test your pipeline. From the frontend tier, try to reach the backend repeatedly. Does it fail *every* time, or *intermittently*? Intermittent failure is a clue — that is packet loss, not a hard outage.

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

## Step 3: The Fleet Fights Back (GitOps Self-Heal)

Here is the first thing to notice: **you are already surviving.**

The Pirate keeps killing your pods — but your Day 2 **Deployments** respawn them, and your Day 3 **ArgoCD** self-heal drags every change back to the Captain's Log. The automation you built earlier this week is, right now, fighting the Pirate for you without you typing a thing.

1. Open ArgoCD (`argocd.{{ lab_domain }}`). Watch it flip **OutOfSync → Synced** over and over as it heals the pod-kills.
2. **Lesson:** resilient architecture is not about *preventing* failure. It is about *recovering* from it automatically.

## Step 4: Raise the Blockade (Defend Your Namespace)

Pod-kills you can survive. The `NetworkChaos` packet loss is harder — you must harden your borders.

1. Ask your AI (you will switch it to the **Incident Commander** persona after lunch — for now the Boatswain still helps): *"How do I write a NetworkPolicy that only allows ingress from my alliance's namespaces and denies everything else?"*
2. Each tier writes a `NetworkPolicy` that admits traffic **only** from its alliance partners — and nothing else. A tightly scoped allow-list gives the Pirate's agent far less room to operate.
3. Apply it the GitOps way — commit it to your repo and let ArgoCD ship it. Stay disciplined even under fire.

## Step 5: Stabilize and Report

You succeed when your 3-tier pipeline serves traffic **reliably** for 60 straight seconds while the attack is still running.

1. Hammer your frontend in a loop and confirm clean responses:
   ```bash
   while true; do curl -s -o /dev/null -w "%{http_code}\n" http://<frontend-svc>; sleep 1; done
   ```
2. When it holds steady, call your instructor for the post-incident review.

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
