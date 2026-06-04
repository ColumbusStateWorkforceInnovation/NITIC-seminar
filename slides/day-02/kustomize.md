---
marp: true
auto-scaling: false
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 2 · Kustomize"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 2 · Opening Demo · 10 minutes

# Kustomize

## One base, many ships

*Yesterday you each pushed a raft. Overnight I changed all of them with one file. Watch.*

<!-- 10 minutes. Open the day with this. No student keyboards. The pedagogical move is: the room walks in, they don't yet know their raft has been changed, and you show them how using one file. The "ah, that's how the instructor handles 30 of us" moment lands before any new lecture content. -->

---

## What just happened to your raft

- Yesterday at end-of-day, every student's namespace had **`raft-fleet/<your-name>:v1`** running as a Pod.
- This morning, every namespace is running **`<your-name>:v2`** — different background, different message.
- I did not touch your namespace. I touched **one file**.
- That file is called a **Kustomize overlay**, and it is the single most useful operator's tool in Kubernetes.

*Pull up `k9s` and confirm. Your Pod is on v2.*

<!-- Have a student pull up k9s on the projector. The image tag visibly says v2. Let the room react. -->

---

## Two different problems

| Problem | Tool |
| :--- | :--- |
| Same shape, different *parameters* (image tag, namespace, replicas) for many copies | **Kustomize** — patches over a base |
| Same shape, packaged as a *product* you hand someone else to install | **Helm** — templates + values (tomorrow) |

- Kustomize is the tool the **operator** reaches for.
- Helm is the tool the **publisher** reaches for.
- Today you only need to recognise the shape of Kustomize — so when ArgoCD reads its overlays on Day 3, it isn't a surprise. Helm you'll *write* tomorrow.

<!-- Plant the operate-vs-publish framing now. Helm shows up tomorrow morning and answers a different question. -->

---

## The shape of what I ran
<!-- _class: diagram-sm -->

```text
kustomize-demo/
├── base/
│   └── raft-pod.yaml          ← the Day 1 Pod (image is a placeholder)
└── overlays/
    └── all-students/
        └── kustomization.yaml ← one images: override, rewritten per student
```

```yaml
# overlays/all-students/kustomization.yaml (excerpt)
images:
  - name: harbor.wagbiz.org/raft-fleet/raft   # placeholder in base
    newName: harbor.wagbiz.org/raft-fleet/raft # rewritten per student at apply
    newTag: v2
```

*One overlay shape. The loop parameterises its image per student.*

<!-- Show the file in the projector terminal. Don't deep-dive — the point is "this is plain YAML, nothing magic." -->

---

## The loop I ran at 7am
<!-- _class: code-sm -->

```bash
for ns in $(kubectl get ns -l role=student -o name); do
  student="${ns#namespace/student-}"
  ( cd overlays/all-students && \
    kustomize edit set image \
      "harbor.wagbiz.org/raft-fleet/raft=harbor.wagbiz.org/raft-fleet/${student}:v2" && \
    kubectl apply -k . -n "${ns#namespace/}" )
done
```

- For each student namespace, `kustomize edit set image` rewrites the overlay's image override to that student's v2 repo.
- `kubectl apply -k .` updates the existing `my-raft` Pod in-place — same Pod, new image.
- **Wall-clock: ~4 seconds.** Cluster-wide.

*This is how I will give you each a Deployment in 10 minutes from now. And a Service this afternoon. And a 3-tier app this afternoon.*

<!-- Land the punchline: this is what makes the rest of the week possible. The instructor isn't hand-typing your environment. One overlay shape, parameterised per student. -->

---

<!-- _class: lead -->
<!-- _footer: "" -->

## Now: meet Captain Kube.

*That's all you need to know about Kustomize today. The lecture starts now.*

<!-- Hand-off to the K8s architecture lecture. The Kustomize concept is planted — when Helm shows up on Day 3, you can callback: "remember Tuesday morning? That was the operator tool. Today Hazel is the publisher tool." -->
