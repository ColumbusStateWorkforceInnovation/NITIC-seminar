# Day 4: The Admiral's Challenge

```text
        |    |    |
       )_)  )_)  )_)
      )___))___))___)\
     )____)____)_____)\\
   _____|____|____|____\\\__
   \   PIRATE  STRIKES   /
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
*The final day. The Pirate boards the cluster, the fleet endures the chaos, and the crew proves they are ready to sail alone.*

## 🕘 The Schedule
- **09:00 - 10:30** | Lecture & Demo: Cloud-Native Classrooms (vCluster, KubeVirt, Chaos)
- **10:30 - 10:45** | ☕ Break
- **10:45 - 12:00** | Lab / Game: The Pirate Strikes! (Survive the Chaos)
- **12:00 - 01:00** | 🥪 Lunch
- **01:00 - 02:30** | AI Connect: The Paradigm Shift (The Incident Commander)
- **02:30 - 02:45** | ☕ Break
- **02:45 - 04:15** | Discussion: The Educator's Strategic Roundtable
- **04:15 - 05:00** | Wrap-Up: Trivia & Send-Off

---

## ⚓ The Incident Responder's Cheat Sheet

### Triage Under Fire
* **Watch the fleet live:** `k9s`
* **Read the incident report:** `kubectl get events -n <ns> --sort-by=.lastTimestamp`
* **Find the saboteur:** `kubectl get podchaos,networkchaos -A`
* **Inspect an attack:** `kubectl describe networkchaos <name> -n chaos`
* **Probe a service in a loop:** `while true; do curl -s -o /dev/null -w "%{http_code}\n" <url>; sleep 1; done`

### Defend the Namespace
* **NetworkPolicy:** allow ingress only from your alliance — deny everything else.
* **Ship it the GitOps way:** commit the policy, let ArgoCD sync it.
* **Let the automation work:** Deployments respawn killed pods; ArgoCD self-heals drift.

### The Paradigm Shift (AGENTS.md)
> For 3 days the Boatswain was Socratic — *no answers, only hints*.
> Mid-incident, that is wrong. Overwrite it into the **Incident Commander**:
> one-sentence root cause, then the exact copy-pasteable fix. **Matching the AI
> to the urgency of the task is the skill.**

---

## 📝 Captain's Log (Final Notes)

*(What will you Start, Stop, and Continue back at your own college?)*

<br><br><br><br><br><br><br><br>
