# Instructor Guide: Day 3 (Automated Shipyards)

Day 3 is the leap from *manual* operations to *automated* ones. The students stop running `kubectl apply` by hand and hand the wheel over to Hazel (Helm) and the Automated Shipyards (GitOps). The afternoon is the most ambitious of the week — pace it deliberately.

## 09:00 - 09:30 | The Finished Vessel (3-tier walkthrough, 30-min opening demo)
**Goal:** Finish what Day 2 started. Walk the complete 3-tier app end to end so the room sees the whole machine working *before* they templatize it. This is the concrete target the Helm lab builds against — same app, one level up.

- **Reference:** [`demo-fleet-logistics.md`](../day-02/demo-fleet-logistics.md) — the full 30-min run-sheet (minute-by-minute beats, the silent-broken-link and Gateway API segments, manifests in [`fleet-demo/`](../day-02/fleet-demo/), and the [`gateway-api-personas`](../../../slides/day-02/gateway-api-personas.md) slides). **Pre-flight:** run `scripts/fleet-demo-setup.sh` first (namespaces + `/etc/hosts` + gateway check).
- **Action:** Instructor-led demo, no student keyboards. Show the app as one connected system: the **3 namespaces**, the **3 Deployments** (frontend, backend, cache), the **3 Services** wiring them together, and the **single Gateway API** that exposes the whole thing at `wagbiz.org`. Open the live URL so they see it actually serving.
- **Action (trace the request out loud):** browser → Gateway API → frontend Service → backend Service → cache. Pull up each object in `k9s` as you name it. The goal is that every student can draw the box-and-arrow diagram from memory by 09:30.
- **Talking Point (the hook for the whole day):** *"You hand-built these pieces in your alliances yesterday. This morning you see them connected and serving. After the break, you stamp the entire stack from one blueprint."*
- **Note:** the old in-cluster CI opener (Gitea Actions, `git push → image in Harbor`) is **retired as the opener**. If a student asks about the build half, give it one line and point them at the Lab 02 stretch goal — don't detour the demo.
- **Hand off** at 09:30 with the lead slide: *"Now: meet Hazel. You've seen the finished vessel. Today you learn to mass-produce it."*

## 09:30 - 10:30 | The Problem With Raw YAML (Lecture, 60 min)
**Goal:** Make the students *feel* the pain of copy-pasting YAML before you sell them the cure. **60 minutes — the morning demo took the first 30.**

- **Callback:** open by referencing Tuesday morning's Kustomize demo: *"Yesterday you met the operator's tool. Today you meet the publisher's tool. They are not rivals — half the field uses both."*
- **Action (Storytime, ~2 min):** Project the *Admiral Bash's Island Adventure* PDF and read **pp. 22–23** — Hazel the Helm Hedgehog noticing the penguins were reinventing the wheel and assembling reusable charts at "No More Wheels". This is the lecture in one spread: stop hand-writing the same YAML; templatize it.
- **Action:** Distribute the printed `one-pager.md`.
- **Talking Point (The Pain):** Ask the room: "Yesterday you wrote a Deployment and a Service for *one* tier. Now imagine deploying that 3-tier stack for all 30 of your students. That's 180 hand-edited YAML files." Let that land.
- **Lecture:** Introduce Helm — `Chart.yaml`, `values.yaml`, the `templates/` directory, and Go-templating ({% raw %}`{{ .Values.x }}`{% endraw %}). Frame `values.yaml` as the "ship's blueprint" and the templates as the "mass-production mold."
- **Talking Point (Instructor Superpower):** "Helm is how you stop being a YAML typist. One chart, thirty `values.yaml` files, thirty identical lab environments. This is the single biggest time-saver you will see this week."
- **Pacing note:** with 60 min instead of 90, skip the deep dive into named templates / partials — the lab will surface that detail organically.

## 10:45 - 12:00 | Lab 01: Drafting the Blueprint
**Goal:** Students convert their Day 2 3-tier app into a reusable Helm chart.

- **Action:** Have students open `lab-01-drafting-the-blueprint.md` on the docs site (`docs.{{ lab_domain }}`).
- **Action (The Trap):** Let them try to hand-write Go-template syntax. They will mangle the {% raw %}`{{ }}`{% endraw %} braces. Let them struggle for a few minutes.
- **Action (The Save):** Remind them the Boatswain is still on duty — but it will *not* write the loop for them (that is Rule Update 3, coming this afternoon — for now it still gives concept-only hints).
- **Game (Templating Speed Run):** Once charts are installed, call it: "First pirate to run `helm upgrade` and push their replica count to 5 — verified in `k9s` — takes the round." Watch for students who edit `values.yaml` vs. those who use `--set`; both are valid, discuss the difference.
- **Talking Point:** "Notice nobody re-applied a Service. Helm tracked every object in the release. One command upgraded the whole stack."

## 01:00 - 01:45 | Git Is Truth (Lecture, 45 min)
**Goal:** Explain GitOps before the afternoon lab — the mental model matters more than the tool. **45 minutes — keep it tight; the lab is where it lands.**

- **Lecture:** Introduce GitOps. The core idea: the Git repo is the **desired state** ("Captain's Log"); the cluster is the **live state** ("Crew's Actions"). ArgoCD's only job is to make the second match the first.
- **Lecture:** Tour the internal tooling — Gitea (`gitea.{{ lab_domain }}`) as the island's Git server, Harbor (`harbor.{{ lab_domain }}`) as the registry, ArgoCD (`argocd.{{ lab_domain }}`) as the sync engine.
- **Note:** the prize/flash-poll round moved to the **end of the day** (16:15) — by then the room has *done* the ArgoCD self-heal lab, so every question is earned. Do not run it here.

## 01:45 - 02:45 | Lab 02: The Automated Shipyard (Part 1)
**Goal:** Students wire a full Git → ArgoCD → cluster sync loop. This is the afternoon's centerpiece — protect the time.

- **Action:** Students follow `lab-02-the-automated-shipyard.md` — push their Lab 01 chart to a Gitea repo, then create an ArgoCD `Application` that watches it. By the break, every student should have a **Healthy / Synced** card.

## 02:45 - 03:00 | ☕ Break

## 03:00 - 03:40 | Lab 02: Self-Heal & the Raid

- **Action (The Mutiny, solo — Step 3):** Once a student is synced, have them `kubectl scale` (or `kubectl delete`) *their own* deployment behind ArgoCD's back. The card flips to **OutOfSync**; with Self-Heal on, ArgoCD drags it back. This is the warm-up "aha."
- **Action (The Raid, collaborative — Step 4):** *"With the rights the Admiral granted you, go delete a **crewmate's** deployment."* Their neighbor's ArgoCD heals it within seconds. Then land the punchline: the only way to actually change a crewmate's fleet is a **pull request** against their repo. **`kubectl` is a suggestion; Git is the law.** *(Requires the broadened RBAC grant — see Pre-Flight. If it isn't in place, run as a paired demo on one screen.)*
- **Action (Close the loop, ~2 min):** *"Edit your chart, push to Gitea, watch."* ArgoCD syncs, the new version rolls out, the live URL shows the change — the full `git push → live app` story, in their own cluster.
- **Optional talk-through ([`slides/day-03/all-hands-on-deck.md`](../../slides/day-03-all-hands-on-deck.html)):** if the room is energized by the raid, spend 5 minutes on the collaboration menu — the PR Raid, Chain Reaction, Town Square, Fix-My-Broken-Chart — and the platform-engineering **division of labor** (produce → consume → verify: the reusable workflow, the golden Helm chart, the golden base image). It dovetails straight into the Quartermaster's Manifest.

## 03:40 - 04:15 | The Quartermaster's Manifest (Lecture, ~30–35 min)
**Goal:** Lift their eyes off the keyboard. Show the room everything a platform like this can *teach*, then give them the name for what they built all week — **platform engineering**.

- **Reference:** slides at [`slides/day-03/the-quartermasters-manifest.md`](../../slides/day-03-the-quartermasters-manifest.html).
- **Part I — The Hold (~10 min, brisk):** walk the menu by discipline so every instructor finds their own subject (Python/data, AI/ML, web/JS, systems/C++, networking, DevOps/SRE, databases/security). **This is where Clabernetes now lives** — one item on a long shelf, named as the EVE-NG/GNS3 replacement, *not* run as a hands-on lab. Land the five subject-independent superpowers.
- **Part II — Platform Engineering (~20 min, the real payload):** the reveal ("you've been a platform team all week"), the sysadmin → DevOps → platform-engineering arc, and the vocabulary (IDP, golden path/paved road, platform-as-product, cognitive load, the CNCF maturity ladder). Close on the four-question pocket test and the Monday-morning first step.
- **Framing rule:** agency, not grievance. The hook is *"the environments you can choose to support have radically expanded"* — and now they have the words and the tools to build them on purpose.
- **Hand off to Day 4:** the broad menu narrows tomorrow morning to three deep dives — vCluster, KubeVirt, Chaos — then the Pirate strikes.

## 04:15 - 04:40 | The Flash Poll — Closing Round

- **Action (Flash Poll):** Open the Quiz App (`poll.{{ lab_domain }}`) and load `quiz-content.quizler`. Run the 5 questions as the day's closing beat. Helm `values.yaml`, `helm upgrade`, "Git is truth," ArgoCD self-heal, OutOfSync — all things the room *did* today, so it plays as a victory lap, not a test.
- **Logistics note:** any end-of-day recognition tied to the poll is the instructor's to run off-script — it is deliberately kept out of the written curriculum.

## 04:40 - 05:00 | AI Connect & Debrief (20 min)

- **Action:** Have students append **Rule Update 3** to `~/lab/AGENTS.md` and re-launch `hail` to pick up the new rule (see the side-quest in `day-03-automated-shipyards.md`). This makes the Boatswain refuse to debug an OutOfSync app until the student explains desired vs. live state.
- **Game:** Have a student manually `kubectl delete` a pod from an ArgoCD-managed app and ask the Boatswain why it respawned. The AI should force them to articulate the reconciliation loop.
- **Action (Storytime, ~2 min):** Project the PDF and read **pp. 28–31** to close the day — Goldie's build machine with the conveyor belt of clusters, the scorpion gatekeeper enforcing admission policy, and the Flux-bots deploying from Git. This is the perfect bridge into Day 4: the pipeline you just built is what tomorrow's pirate will try to subvert.

## 🧰 Pre-Flight Checklist (before class)

- [ ] **The 3-tier app is deployed and serving live at `wagbiz.org`** — this is the 09:00 demo. Click through it yourself the night before: all 3 namespaces present, all 3 Deployments Ready, all 3 Services with endpoints, the Gateway API routing. If yesterday's group build didn't finish, stand up the reference version so the demo is rock-solid.
- [ ] **Clear the student namespaces** so Lab 01 has room — run **`just clear-decks`**. Each `student-<name>` namespace has a hard **500m CPU quota** (≈5 pods at the 100m LimitRange default); Day 2's leftover hand-built fleets eat 200–500m of it, so without this a fresh Lab 01 `helm install` exceeds quota and pods sit **Pending** — the single biggest source of "I'm stuck" tomorrow. Verify with `kubectl get quota -A | grep student-` (used CPU ~0). Re-run if anyone redeploys Day 2 work.
- [ ] Helm is on every client VM (`setup-client.sh` installs it — verify with `helm version`).
- [ ] Gitea, Harbor, and ArgoCD are all up and reachable (`just deploy-gitea deploy-harbor deploy-argocd`).
- [ ] **Mailpit (mock SMTP) is wired** so the inbox at <https://mailpit.{{ lab_domain }}> isn't empty. Gitea, Grafana, and ArgoCD pick it up automatically when you (re)deploy them. **Harbor and Rancher each need one extra step:** run `just harbor-mail` after `deploy-harbor`, and add the SMTP notifier by hand in the Rancher UI (server `mailpit.admin-tools.svc.cluster.local`, port `1025`, no TLS, no auth). See `day-03/sso-walkthrough.md` for the full tiering.
- [ ] Each student can log into Gitea and create a repo.
- [ ] **Broadened RBAC for the collaborative Raid (Lab 02, Step 4)** is applied: run **`just grant-raider`**. Cohort-wide read is already covered by `grant-explorer`; this adds `delete`/`patch` on Deployments + Services in *other* student namespaces (per-namespace RoleBindings to `system:authenticated` — never admin-tools/argocd/kube-system, and never secrets). **Confirm Self-Heal is on for every student `Application`** so sabotage always reverts. Tear it back down after Day 3 with **`just revoke-raider`**. *(Verify: a student token gets `yes` on `kubectl auth can-i delete deployment -n student-<someone-else>`.)*
- [ ] **The Quartermaster's Manifest deck** renders — `just slides` (or render `slides/day-03/the-quartermasters-manifest.md`). Skim the speaker notes once; the platform-engineering half is the part to rehearse.
- [ ] **Quizler flash poll** is up at `poll.{{ lab_domain }}` with `quiz-content.quizler` loaded for the 16:15 closing round.
- [ ] Grab the ArgoCD admin password ahead of time so you are not scrambling: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`.
- [ ] *(Optional)* the old Gitea Actions demo is retired as the opener but still works as the Lab 02 stretch goal — only needs the `gitea-act-runner` if a student attempts it.

## 🔧 Troubleshooting

### Rancher: `{"data":"no available server"}` / 503, pod in `CrashLoopBackOff`

**Symptom.** `https://rancher.{{ lab_domain }}` (and even `/ping` and `/healthz`) returns HTTP 503 with body `{"data":"no available server"}`. The gateway is up, but the `rancher` Service has **no endpoints** because the single Rancher pod never reaches Ready — `kubectl get pods -n cattle-system` shows it in `CrashLoopBackOff` with a high restart count.

**Root cause.** The `v1.ext.cattle.io` APIService is `False (MissingEndpoints)`. It's an *aggregated* API served by the Rancher pod itself (port 6666), so while the pod is unhealthy it has no backing endpoints — and an unavailable aggregated APIService stalls **cluster-wide API discovery**. Rancher's own startup does heavy discovery, so its `/healthz` can't answer within the probe timeout; the kubelet kills the pod, and it never recovers because the stale APIService poisons discovery on every boot. It is **not** a resource problem (check `kubectl top node` — the node is typically near-idle) and **not** a bad `RANCHER_TOKEN`.

**Diagnose.**
```sh
kubectl get pods -n cattle-system                      # rancher pod CrashLoopBackOff?
kubectl get endpoints rancher -n cattle-system         # empty ENDPOINTS column
kubectl get apiservice v1.ext.cattle.io                # AVAILABLE = False (MissingEndpoints)
kubectl describe pod -n cattle-system <rancher-pod>    # Events: Liveness/Startup probe failed on /healthz
```

**Fix.** Delete the stale APIService to unblock discovery, then restart Rancher. Once Rancher reaches Ready it re-registers the APIService with itself as a healthy endpoint (it flips back to `True`), and the Service gets endpoints again.
```sh
kubectl delete apiservice v1.ext.cattle.io
kubectl -n cattle-system rollout restart deploy/rancher
kubectl -n cattle-system rollout status deploy/rancher --timeout=300s
# verify: curl -sk -o /dev/null -w '%{http_code}\n' https://rancher.{{ lab_domain }}/ping   # → 200
```

**Note.** This is a known Rancher 2.14 chicken-and-egg on restart — it can recur after any unclean Rancher restart (node reboot, OOM, redeploy). The two-command fix above is safe to re-run.
