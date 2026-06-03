# Demo: Kustomize (the operator's tool)

> **Slot:** Day 2, 09:10 – 09:20 (10 min, between storytime and the K8s architecture lecture)
> **Audience:** mixed students + faculty
> **Mode:** instructor-led demo, no student keyboards
> **Slides:** [`slides/day-02/kustomize.md`](../../slides/day-02-kustomize.html)
> **Manifests:** [`kustomize-demo/`](kustomize-demo/)

This is **not a lab**. It is a 10-minute demo whose only job is to land one
claim with the room before the K8s architecture lecture: **the reason
your environment showed up in your namespace this week is one file called a
Kustomize overlay.**

The demo lands hardest if students walk in to discover their **Day 1 raft
Pod is already on v2** — different background colour, different message —
and the instructor reveals "I changed all thirty of you with one file"
*after* they see the change.

## 🧑‍🏫 Instructor Superpower: Operate vs. Publish

*Kustomize is the tool faculty reach for when **operating** their own stack
— thirty per-student environments from one file, cluster-wide image bumps
from a single line edit. Helm (tomorrow) is the tool for **publishing**
charts to someone else. Land the distinction here so when Hazel arrives
Wednesday, the room already has somewhere to put her.*

## 🛠 Pre-Flight (the night before, ~10 min)

The whole demo depends on every student's raft Pod going from `v1` to `v2`
during the morning. That happens by you running the apply loop — one
`kustomize edit set image` per student to rewrite the overlay's image
override, then `kubectl apply -k` into that student's namespace.

1. Build a `v2` raft image **per student** with a visible change — easiest
   is `FROM harbor.wagbiz.org/raft-fleet/<student>:v1` plus a small banner
   layer (different background colour and headline message). Push each as
   `harbor.${LAB_DOMAIN}/raft-fleet/<student-name>:v2`. Script this once
   and reuse — see [`scripts/build-fleet-v2-images.sh`](../../../scripts/build-fleet-v2-images.sh)
   if you've created one, or wrap the build/push in your own loop.
2. Verify the overlay renders cleanly (placeholder image, v2 tag):
   ```bash
   cd docs/missions/day-02/kustomize-demo
   kubectl kustomize overlays/all-students/
   ```
3. Stage the apply loop. Note the `kustomize edit set image` step —
   that's what makes one overlay shape cover thirty per-student images:
   ```bash
   cd docs/missions/day-02/kustomize-demo
   for ns in $(kubectl get ns -l role=student -o name); do
     student="${ns#namespace/student-}"
     ( cd overlays/all-students && \
       kustomize edit set image \
         "harbor.wagbiz.org/raft-fleet/raft=harbor.wagbiz.org/raft-fleet/${student}:v2" && \
       kubectl apply -k . -n "${ns#namespace/}" )
   done
   # Reset the overlay back to the placeholder shape so future renders are clean.
   ( cd overlays/all-students && \
     kustomize edit set image \
       "harbor.wagbiz.org/raft-fleet/raft=harbor.wagbiz.org/raft-fleet/raft:v2" )
   ```
4. **Apply it before 09:00 on Day 2.** Students walk in to v2 — their
   existing `my-raft` Pod is updated in-place (same Pod name, new image).

Optional but more dramatic: don't apply at 07:00 — apply it **at 09:11**,
live in front of the room, with a student's `k9s` on the projector. The
room watches the in-place image update happen in real time.

## ⏱ The Run-Sheet

| Time | Beat | What you do |
| :--- | :--- | :--- |
| 00:00 – 01:00 | "What just happened" | Slide 2. Pull a student's k9s up on the projector. Image tag visibly reads v2. Let the room react. |
| 01:00 – 02:30 | Two problems, two tools | Slide 3 (table). Plant the operate-vs-publish distinction. Helm shows up tomorrow. |
| 02:30 – 05:00 | The shape on disk | Slide 4. `cat overlays/all-students/kustomization.yaml`. Point at `images: newTag: v2`. That's the whole change. |
| 05:00 – 08:00 | The apply loop | Slide 5. If you did the live-apply variant, this is where you ran it. Either way, narrate "I touched one file, the cluster did thirty rollouts." |
| 08:00 – 10:00 | Hand off to the lecture | Lead slide. "That's all you need to know about Kustomize today. Captain Kube takes the wheel." |

## 📎 What the room takes away

- The word **Kustomize**, and the fact that they can read its files (plain YAML).
- The concept of a **base + overlay** — one shape, many copies.
- The framing **operator vs. publisher** — so when Helm arrives Wednesday they have a slot for it.

That's it. Don't teach `namePrefix`, `commonLabels`, JSON-6902 patches, or
strategic-merge patches today. Those are operator detail; the room is
two days from caring. Hazel will earn her own lecture tomorrow.

## 🪢 Callbacks for the rest of the week

- **Day 2 morning lab** (after this demo): when students write their first
  Deployment, the instructor can quietly use the same overlay pattern to
  give the room a starter Deployment if anyone gets stuck — frame it as
  "I just used the thing I showed you at 09:10."
- **Day 3 Helm lecture**: open with *"remember Tuesday morning? That was
  the operator tool. Today Hazel is the publisher tool. They are not
  rivals — half the field uses both."*
- **Day 3 ArgoCD lab**: when you show the ArgoCD Application spec, point
  at the `kustomize:` block. "ArgoCD reads the same overlays you saw on
  Tuesday — that's why I can ship updates to your environment without
  touching your namespace."
- **Day 4 capstone**: the per-student namespace targeting in the chaos
  experiments uses the same `namespaces:` selector pattern the overlay
  used. "Same idea, different CRD."

## 🧯 If something goes wrong

- **Students walk in and Pods are still v1.** You forgot the pre-flight
  apply. Run the loop live as part of the demo — same effect, more
  dramatic. Bonus: students see the apply happen.
- **One student's namespace doesn't get the bump.** Probably a namespace
  label drift — `kubectl get ns <name> --show-labels` and confirm
  `role=student` is present. If not, label it and rerun the loop.
- **`kubectl kustomize` complains about apiVersion.** Your `kubectl` is
  older than the embedded Kustomize. Run `kubectl version --client`; if
  client is <1.21, install the standalone `kustomize` binary and use that
  in the loop.
