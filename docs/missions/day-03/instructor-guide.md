# Instructor Guide: Day 3 (Automated Shipyards)

Day 3 is the leap from *manual* operations to *automated* ones. The students stop running `kubectl apply` by hand and hand the wheel over to Hazel (Helm) and the Automated Shipyards (GitOps). The afternoon is the most ambitious of the week — pace it deliberately.

## 09:00 - 09:30 | Gitea Actions (in-cluster CI, 30-min opening demo)
**Goal:** Open Day 3 with the **build half** of CI/CD — `git push` to tagged image in Harbor, in-cluster, no off-cluster dependency. Hear the names Argo Workflows and Tekton on the way out. ArgoCD picks up the loop in the afternoon as a callback.
- **Reference:** [`demo-gitea-actions.md`](demo-gitea-actions.md) (run-sheet + bailouts), slides at [`slides/day-03/gitea-actions.md`](../../../slides/day-03/gitea-actions.md), example workflow at [`gitea-actions-demo/.gitea/workflows/ci.yaml`](gitea-actions-demo/.gitea/workflows/ci.yaml).
- **Action:** Instructor-led demo, no student keyboards. The 6 minutes of "live push-to-image" (slide 6) are the demo — push a one-character change to the Gitea raft-fleet repo, narrate the two browser tabs (Gitea Actions → Harbor). **Do not show ArgoCD here** — it hasn't been taught yet.
- **Talking Point:** "The original course outline named GitHub Actions. The YAML you just saw runs unchanged on github.com under `.github/workflows/`. We chose to host it in our cluster — same syntax, fewer dependencies."
- **Foreshadow:** "The image is sitting in Harbor now, waiting. After lunch we'll meet ArgoCD, which picks it up. That closes the loop."
- **Bailout:** keep the demo recording open in a hidden tab. If the live run stalls past 90 seconds, cut to it without apology.
- **Pre-flight:** see [`demo-gitea-actions.md`](demo-gitea-actions.md) → Pre-Flight.
- **Hand off** at 09:30 with the lead slide: *"Now: meet Hazel. You've seen the build half. The template + deploy halves are the rest of today."*

## 09:30 - 10:30 | The Problem With Raw YAML (Lecture, 60 min)
**Goal:** Make the students *feel* the pain of copy-pasting YAML before you sell them the cure. **60 minutes — was 90; the morning demo took 30.**
- **Callback:** open by referencing Tuesday morning's Kustomize demo: *"Yesterday you met the operator's tool. Today you meet the publisher's tool. They are not rivals — half the field uses both."*
- **Action (Storytime):** Project the PDF and read the "Day 3 Morning" passage from `book-readings.md`.
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

## 01:00 - 02:30 | Git Is Truth (Lecture)
**Goal:** Explain GitOps before the afternoon lab — the mental model matters more than the tool.
- **Lecture:** Introduce GitOps. The core idea: the Git repo is the **desired state** ("Captain's Log"); the cluster is the **live state** ("Crew's Actions"). ArgoCD's only job is to make the second match the first.
- **Lecture:** Tour the internal tooling — Gitea (`gitea.{{ lab_domain }}`) as the island's Git server, Harbor (`harbor.{{ lab_domain }}`) as the registry, ArgoCD (`argocd.{{ lab_domain }}`) as the sync engine.
- **Action (Flash Poll):** Open the Quiz App (`poll.{{ lab_domain }}`) and load `quiz-content.quizler`. Run the 5 questions to check the Helm + GitOps mental model before turning them loose.

## 02:45 - 04:15 | Lab 02 & Demo: The Automated Shipyard
**Goal:** Students wire a full Git → ArgoCD → cluster sync loop. **This block is tight — protect it.**
- **Action:** Students follow `lab-02-the-automated-shipyard.md` — push their Lab 01 chart to a Gitea repo, then create an ArgoCD `Application` that watches it.
- **Action (The Mutiny / Ghost Ship):** Once a student is synced, have them `kubectl edit deployment` and scale replicas to 10. ArgoCD flags **OutOfSync**. They hit **Sync** and watch it heal back to the Git value. This is the "aha" — drive it home.
- **Action (The Live Classroom Demo):** Run the JupyterLab demo from `lab-02`'s instructor demo section. Commit a chart change, watch ArgoCD ship a data-science environment to the class. This is the headline Instructor Superpower of the week.
- **Action (Closing the morning loop, ~2 min):** *"Remember the tag we pushed to Harbor at 09:15 — Gitea Actions built it, it's been sitting there all day. Watch."* Open ArgoCD → raft Application → Sync. The image rolls out. Refresh the live URL. The morning's edit is now visible. **This is the close-the-loop moment.** Under 60 seconds.
- **Pacing call:** If the room is moving slowly, run **Lab 03 (Clabernetes)** as an instructor-led *demo* only — do not force all students through it. It is written to work either way.

## 04:15 - 05:00 | AI Connect & Debrief (45 min)
- **Action:** Have students append **Rule Update 3** to `~/lab/AGENTS.md` and re-launch `hail` to pick up the new rule (see the side-quest in `day-03-automated-shipyards.md`). This makes the Boatswain refuse to debug an OutOfSync app until the student explains desired vs. live state.
- **Game:** Have a student manually `kubectl delete` a pod from an ArgoCD-managed app and ask the Boatswain why it respawned. The AI should force them to articulate the reconciliation loop.
- **Action (Storytime):** Project the PDF and read the "Day 3 Afternoon" passage from `book-readings.md` to close the day.

## 🧰 Pre-Flight Checklist (before class)
- [ ] Helm is on every client VM (`setup-client.sh` installs it — verify with `helm version`).
- [ ] Gitea, Harbor, and ArgoCD are all up and reachable (`just deploy-gitea deploy-harbor deploy-argocd`).
- [ ] **Gitea Actions runner** is deployed and registered — see [`demo-gitea-actions.md`](demo-gitea-actions.md) → Pre-Flight. `gitea-act-runner.yaml` in `k8s/core-tools/` is the manifest; needs a `act-runner-token` secret from Gitea admin UI before apply.
- [ ] **The Gitea Actions demo recording** exists on the instructor laptop in case the live run stalls.
- [ ] **Mailpit (mock SMTP) is wired** so the inbox at <https://mailpit.{{ lab_domain }}> isn't empty during the demo. Gitea, Grafana, and ArgoCD pick it up automatically when you (re)deploy them. **Harbor and Rancher each need one extra step:** run `just harbor-mail` after `deploy-harbor`, and add the SMTP notifier by hand in the Rancher UI (server `mailpit.admin-tools.svc.cluster.local`, port `1025`, no TLS, no auth). See `day-03/sso-walkthrough.md` for the full tiering.
- [ ] Each student can log into Gitea and create a repo.
- [ ] **Clabernetes** is installed if you intend Lab 03 as hands-on (see lab-03 — it is *not* part of `deploy-core`).
- [ ] Grab the ArgoCD admin password ahead of time so you are not scrambling: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`.

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
