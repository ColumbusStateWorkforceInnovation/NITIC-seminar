# Demo: Gitea Actions (in-cluster CI)

> **Slot:** Day 3, 09:00 – 09:30 (30 min, opens the day)
> **Audience:** mixed students + faculty
> **Mode:** instructor-led demo, no student keyboards
> **Slides:** [`slides/day-03/gitea-actions.md`](../../slides/day-03-gitea-actions.html)
> **Workflow:** [`gitea-actions-demo/.gitea/workflows/ci.yaml`](gitea-actions-demo/.gitea/workflows/ci.yaml)

This demo opens Day 3 with the **build half** of CI/CD. The submitted course
outline named **GitHub Actions** as the Day 3 spine. We've taught
**ArgoCD / GitOps** instead — a fundamentally better fit for in-cluster
Kubernetes — but a student reading the abstract deserves to see Actions
semantics in their cluster. The build half lives here at 09:00; ArgoCD
closes the loop in the afternoon with a brief callback once teams have
the ArgoCD UI open.

## 🧑‍🏫 Instructor Superpower: One YAML, Two Homes

*The workflow file in this demo is identical to a GitHub Actions workflow
on github.com. Land that explicitly. A student who learns Gitea Actions
here can copy-paste their `.gitea/workflows/ci.yaml` into a `.github/`
folder on Monday morning and it runs. The cluster portability is the
point — the syntax is just one industry-standard CI language.*

## ⏱ The Run-Sheet

| Time | Beat | What you do |
| :--- | :--- | :--- |
| 00:00 – 03:00 | Frame: where does the image come from? | Slide 2. "Two days, I cheated and pre-built images. Today we fix that." |
| 03:00 – 05:00 | GHA vs. Gitea Actions table | Slide 3 (comparison table). "Same YAML, different home." |
| 05:00 – 08:00 | Walk the architecture | Slide 4 (diagram). Every box is a pod in our cluster. |
| 08:00 – 12:00 | Read the workflow | Slide 5. `cat` the real file from `gitea-actions-demo/.gitea/workflows/ci.yaml`. |
| 12:00 – 18:00 | **Live demo — push to image** | Slide 6. Push, narrate Gitea Actions + Harbor tabs. |
| 18:00 – 22:00 | Why this matters / sidebar setup | Slides 7–8 (chapter slide + "when GA stops being enough"). |
| 22:00 – 25:00 | Argo Workflows sidebar | Slide 9. Don't deep-dive. |
| 25:00 – 27:00 | Tekton sidebar | Slide 10. Same. |
| 27:00 – 29:00 | Decision matrix | Slide 11. "All three run on this cluster. None is wrong." |
| 29:00 – 30:00 | Hand off to Hazel | Lead slide. *"Now: meet Hazel."* |

## 🛠 The live push-to-image (the demo)

This is the 6 minutes of class everything else sets up. Rehearse it twice
the night before — once for timing, once for camera angles on the
projector. Have **two** browser tabs open: **Gitea** and **Harbor**.
(ArgoCD is not part of *this* demo — it comes back as a callback in the
afternoon.)

```bash
# 1. Pull down the demo repo onto your VM and open index.html
git clone https://gitea.${LAB_DOMAIN}/admiral/raft-fleet.git
cd raft-fleet

# 2. Make a one-word change that the room will recognize live.
sed -i 's/The raft is afloat\./The raft is afloat. Shipped by Gitea./' index.html

# 3. Commit and push.
git commit -am "demo: ship a new message"
git push
```

Then **stop typing** and narrate the two browser tabs:

1. **Gitea → Actions tab.** A new run appears within ~5 seconds. Show the live log streaming.
2. **Harbor → `raft-fleet/raft`.** A new tag (the short SHA) lands when the push step finishes.

Wall-clock target: **under 60 seconds from `git push` to new tag in Harbor.**

## 🪢 The afternoon callback (close the loop)

After the ArgoCD lab (around 16:00), do a 2-minute callback:

> *"Remember the tag we pushed to Harbor at 09:15? Watch."*

Open ArgoCD → the `raft` Application. Hit Sync (or let Image Updater do it). The new image rolls out. Refresh the app URL — the morning's edit is now visible. Wall-clock target: another 60 seconds. Loop closed.

## 🧯 If the live demo breaks

This is the highest-risk demo of the week. Build the bailouts in advance.

- **Backup recording.** Screen-record the demo working once, the night before. If the live run stalls past 90 seconds, cut to the recording with: *"While the runner picks up the queue, here's what you'd see — "*. Don't apologize. Don't debug live.
- **Runner not picking up jobs.** Most common failure. `kubectl -n gitea logs -l app=act-runner --tail=50` — the runner needs network to Gitea's API and a valid registration token. If the registration token expired (they're short-lived), regenerate from Gitea admin UI → Site Administration → Actions → Runners.
- **ArgoCD doesn't pick up the new tag.** If you're not running Image Updater, this is expected — hit Sync manually and frame it as "ArgoCD waiting for me to bless the rollout, which is what you'd want in production."
- **Harbor robot login fails.** The `HARBOR_ROBOT_USER` literal contains `$`. In Gitea Actions secrets it must be set with the `$` escaped or stored as `robot$ci`-style without shell interpolation. See `harbor-robot.env` and the deploy-harbor task in `justfile`.

## 🧰 Pre-Flight (the night before)

- [ ] Gitea Actions is **enabled** in `k8s/core-tools/gitea-values.yaml` (see the `ENABLED: true` under `actions:` — added 2026-05-30 as part of this Day 3 addition). Re-`just deploy-gitea` if the values changed.
- [ ] `act_runner` pod is up: `kubectl -n gitea get pods -l app=act-runner` shows `Running 1/1`.
- [ ] Runner is registered with Gitea: Gitea admin UI → Site Administration → Actions → Runners shows the runner online.
- [ ] The `admiral/raft-fleet` Gitea repo exists, has `.gitea/workflows/ci.yaml`, has `Dockerfile`, has `index.html`. The contents in `gitea-actions-demo/` are the source of truth — copy them in.
- [ ] Two Actions secrets exist on the repo (or the org): `HARBOR_ROBOT_USER`, `HARBOR_ROBOT_SECRET`. Pull from `harbor-robot.env`.
- [ ] One Actions variable exists: `LAB_DOMAIN`. Set to your `$LAB_DOMAIN`.
- [ ] Harbor `raft-fleet` project exists (`just bootstrap-harbor` did this on Day 1 — verify the project is there).
- [ ] ArgoCD Application pointing at the raft-fleet chart is **already Synced** before the demo — you're showing the *update*, not the initial sync.
- [ ] The demo recording exists at a known path on the instructor laptop in case live fails.

## 📎 Sidebars (Argo Workflows / Tekton)

The sidebar slides exist so the room hears the names. **Do not demo them.**
The 30-minute budget cannot absorb a second pipeline tool. If a faculty
member asks afterward, point them at:

- Argo Workflows: <https://argoproj.github.io/workflows>
- Tekton: <https://tekton.dev>
- The decision matrix on slide 11.

## 🪢 Hand-off to Hazel (and the afternoon)

Close with the lead slide: *"Now: meet Hazel. You've seen the build half. The template + deploy halves are the rest of today."* That gives the Helm lecture (09:30) a clean opening.

Day 4 callback: if a team wants to **redeploy mid-incident on Day 4** to recover, that's now a feature — they can push a fix to Gitea and watch the runner ship it under fire. Tease this when you do the afternoon ArgoCD callback.
