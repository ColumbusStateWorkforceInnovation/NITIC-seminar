# Salvage Report — The Pirate Strikes

> **Submit this by 12:00 sharp on Day 4** — before lunch. Use the Incident Commander (the AI persona your instructor switches on mid-lab) to help draft it — that's the assignment, not cheating. Your job is to verify, edit, and own what you submit.

**Alliance name:** _e.g. The Black Pearl_

**Namespaces:** _e.g. blackbeard, annebonny, calicojack_

**Roles on the alliance:** _name + tier_
- Frontend:
- Backend:
- Database:

**Incident window:** _start time — end time, with seconds_

---

## § 1. Root Cause (5 sentences max)

*What was attacking you? Be specific — name the Chaos Mesh resource(s), the action, and the selector that targeted you.*

- Resource kind + name(s):
- Action(s):
- Selector(s) that hit your namespace(s):
- What symptom each one produced:

---

## § 2. Timeline

*Real timestamps. The Incident Commander can pull these out of `k9s` paste if you give it your event log. Aim for ~5–10 entries.*

| Time | Event |
| :--- | :--- |
| 10:47 | _Frontend started flickering — 502 on ~30% of requests_ |
| 10:49 | _Pulled `kubectl get events`; saw pod-kill cycle_ |
| ... | ... |

---

## § 3. Recovery Steps (paste the exact commands / YAML)

*This is the runbook section. If a teammate had been out sick today, could they reproduce your fix from this section alone? If no, add detail.*

```bash
# Step 1 (observation): the self-heal was already happening
kubectl get pods -n <ns> -w
# Watched Deployments respawn killed pods; ArgoCD held desired state.
```

```yaml
# Step 2: NetworkPolicy committed to <repo>/<path>
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: alliance-only
  namespace: <ns>
spec:
  podSelector: {}
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              alliance: <alliance-label>
```

```bash
# Step 3 (optional, if you used Gitea Actions): pushed the fix through CI
git commit -am "harden: alliance-only ingress"
git push   # Gitea Actions built + pushed; ArgoCD synced.
```

---

## § 4. Grading Script Output

*Paste the output of `scripts/grade-cluster-recovery.sh <namespace>` here. Your instructor runs this; you record the result.*

```
$ ./scripts/grade-cluster-recovery.sh blackbeard
[paste the script's structured summary]
```

---

## § 5. Prevention Recommendation (this section is yours, not the AI's)

*If you were running this platform in production, what one thing would you change to make this class of incident impossible — or at least loud — next time? One paragraph. Be specific. "Better monitoring" is not an answer; "alert on PodChaos applications via OPA Gatekeeper denying any chaos-mesh.org/v1alpha1 resource outside the chaos namespace" is.*

> _Your recommendation here._

**Why this would have helped:**

> _One or two sentences on why this would have caught the incident earlier or prevented it entirely._

---

## 📋 Rubric (scaffolding, not a competition)

| Section | Points | What earns full credit |
| :--- | ---: | :--- |
| **Cluster restored** (grading script PASS) | 40 | The script exits 0 against your namespace. The one piece you can't skip. |
| **Root cause identified** | 20 | You named the Chaos Mesh kinds attacking you and what each one did. |
| **Recovery steps** | 20 | The commands and YAML you used, written down so the next on-call could rerun them. |
| **Prevention recommendation** | 10 | One specific thing you'd change to make this class of incident louder or rarer next time. |
| **Timeline + metadata** | 10 | Roles filled in, real timestamps, looks like an incident report. |

**Late note:** the cluster gate (40 pts) closes at 12:00 with the bell — submit before lunch. Otherwise, this rubric is more of a structure for the report than a competitive grading sheet; complete reports with a passing grading script are expected to score 100.

**AI use:** the Incident Commander persona drafts §§ 1–4 from your `k9s` paste — that's the point of unlocking it mid-lab. § 5 (Prevention) is yours to write; the AI can suggest options but the call is yours.
