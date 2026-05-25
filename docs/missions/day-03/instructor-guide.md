# Instructor Guide: Day 3 (Automated Shipyards)

Day 3 is the leap from *manual* operations to *automated* ones. The students stop running `kubectl apply` by hand and hand the wheel over to Hazel (Helm) and the Automated Shipyards (GitOps). The afternoon is the most ambitious of the week — pace it deliberately.

## 09:00 - 10:30 | The Problem With Raw YAML (Lecture)
**Goal:** Make the students *feel* the pain of copy-pasting YAML before you sell them the cure.
- **Action (Storytime):** Project the PDF and read the "Day 3 Morning" passage from `book-readings.md`.
- **Action:** Distribute the printed `one-pager.md`.
- **Talking Point (The Pain):** Ask the room: "Yesterday you wrote a Deployment and a Service for *one* tier. Now imagine deploying that 3-tier stack for all 30 of your students. That's 180 hand-edited YAML files." Let that land.
- **Lecture:** Introduce Helm — `Chart.yaml`, `values.yaml`, the `templates/` directory, and Go-templating ({% raw %}`{{ .Values.x }}`{% endraw %}). Frame `values.yaml` as the "ship's blueprint" and the templates as the "mass-production mold."
- **Talking Point (Instructor Superpower):** "Helm is how you stop being a YAML typist. One chart, thirty `values.yaml` files, thirty identical lab environments. This is the single biggest time-saver you will see this week."

## 10:45 - 12:00 | Lab 01: Drafting the Blueprint
**Goal:** Students convert their Day 2 3-tier app into a reusable Helm chart.
- **Action:** Have students open `lab-01-drafting-the-blueprint.md` on the docs site (`docs.{{ lab_domain }}`).
- **Action (The Trap):** Let them try to hand-write Go-template syntax. They will mangle the {% raw %}`{{ }}`{% endraw %} braces. Let them struggle for a few minutes.
- **Action (The Save):** Remind them the Boatswain is still on duty — but it will *not* write the loop for them (that is Rule Update 3, coming this afternoon — for now it still gives concept-only hints).
- **Game (Templating Speed Run):** Once charts are installed, call it: "First pirate to run `helm upgrade` and push their replica count to 5 — verified in `k9s` — wins." Watch for students who edit `values.yaml` vs. those who use `--set`; both are valid, discuss the difference.
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
- **Pacing call:** If the room is moving slowly, run **Lab 03 (Clabernetes)** as an instructor-led *demo* only — do not force all students through it. It is written to work either way.

## 04:15 - 05:00 | AI Connect & Debrief
- **Action:** Have students append **Rule Update 3** to their `AGENTS.md` (see the side-quest in `day-03-automated-shipyards.md`). This makes the Boatswain refuse to debug an OutOfSync app until the student explains desired vs. live state.
- **Game:** Have a student manually `kubectl delete` a pod from an ArgoCD-managed app and ask the Boatswain why it respawned. The AI should force them to articulate the reconciliation loop.
- **Action (Storytime):** Project the PDF and read the "Day 3 Afternoon" passage from `book-readings.md` to close the day.

## 🧰 Pre-Flight Checklist (before class)
- [ ] Helm is on every client VM (`setup-client.sh` installs it — verify with `helm version`).
- [ ] Gitea, Harbor, and ArgoCD are all up and reachable (`just deploy-gitea deploy-harbor deploy-argocd`).
- [ ] Each student can log into Gitea and create a repo.
- [ ] **Clabernetes** is installed if you intend Lab 03 as hands-on (see lab-03 — it is *not* part of `deploy-core`).
- [ ] Grab the ArgoCD admin password ahead of time so you are not scrambling: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`.
