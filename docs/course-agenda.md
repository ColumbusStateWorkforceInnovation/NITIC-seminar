# Admiral Bash's Island Adventure: Seminar Agenda

**Daily Schedule Outline** (9:00 AM - 5:00 PM)
*This is a loose framework to accommodate existing slide decks while reserving massive blocks of time for the hands-on missions.*

---

## Day 1: The Ship Has Sunk (Linux & Containers)

> **Note:** Day 1 opens with a full live VM build — students build an Ubuntu VM (VirtualBox is pre-installed on the classroom desktops) and run the bootstrap script before any lecture. This pushes the Linux/containers and Kubernetes lectures to the afternoon. The Socratic Boatswain is no longer a standalone block; it is introduced inside Lab 01.

| Time | Type | Topic & Activity |
| :--- | :--- | :--- |
| **09:00 - 09:15** | Welcome | Storytime ("Day 1 Morning" reading) & setting the stage. |
| **09:15 - 10:30** | Lab / Setup | **Lab 00 — Building Your Vessel (Pt 1):** Create the VM and launch the Ubuntu installer. |
| **10:30 - 10:45** | Break | *15 Minute Morning Break — Ubuntu installs* |
| **10:45 - 12:00** | Lab / Setup | **Lab 00 — Building Your Vessel (Pt 2):** First boot, clone the repo, run `setup-client.sh`, verify. |
| **12:00 - 1:00** | Lunch | *60 Minute Lunch Break* |
| **1:00 - 1:45** | Lecture | The Wreckage: Linux basics & intro to Containerization. |
| **1:45 - 3:00** | Lab | **Mission:** The First Raft & Claiming Land. Writing Dockerfiles, Instructor Demo, Student Namespaces. |
| **3:00 - 3:15** | Break | *15 Minute Afternoon Break* |
| **3:15 - 4:00** | Lecture | Intro to Kubernetes. Understanding Pods versus Containers. |
| **4:00 - 5:00** | Lab | **Mission:** Paddling Out. Generating `pod.yaml`, `kubectl exec`, reading logs, the Scavenger Hunt & debrief. |

---

## Day 2: Meet the Crew (Deployments & Services)

| Time | Type | Topic & Activity |
| :--- | :--- | :--- |
| **09:00 - 09:10** | Storytime + Day 1 Quiz Warm-up | Read *Admiral Bash* pp. 8–11 (Captain Kube + Goldie); then run Day 1's `quiz-content.quizler` as a 5-min recap. |
| **09:10 - 09:40** | 🚨 Day 1 Catch-Up | **Lab 01 push** (Harbor login now fixed), **Lab 02 §Board the Cluster** (Rancher → kubeconfig → `kubectl get ns`), **Ghost Ship** immutability demo, **Treasure Hunt** (`scripts/day-01-scavenger-hunt.sh`). |
| **09:40 - 09:50** | Demo | **Kustomize:** 10-min opening demo — instructor bumps every student's Day 1 raft Pod from `:v1` to `:v2` with one overlay file. Lands the operate-vs-publish frame before Helm. |
| **09:50 - 10:30** | Lecture | Introduction to K8s Architecture, Deployments, and ConfigMaps. `k9s` intro (trimmed 40 min — Day 1 catch-up took 30). |
| **10:30 - 10:45** | Break | *15 Minute Morning Break* |
| **10:45 - 12:00** | Lab | **Mission:** Deploying the Fleet. CrashLoopBackOff triage with `k9s`. |
| **12:00 - 1:00** | Lunch | *60 Minute Lunch Break* |
| **1:00 - 2:30** | Lecture | Introduction to Networking, Services, and internal DNS. |
| **2:30 - 2:45** | Break | *15 Minute Afternoon Break* |
| **2:45 - 4:15** | Lab | **Mission:** Fleet Logistics. Forming 3-tier alliances and linking Services across boundaries. |
| **4:15 - 5:00** | AI Connect | **Curiosity Side-Quest:** Update `AGENTS.md` to be the Strict Syllabus Enforcer. |

---

## Day 3: Automated Shipyards (Helm, GitOps & Gitea Actions)

| Time | Type | Topic & Activity |
| :--- | :--- | :--- |
| **09:00 - 09:30** | Demo | **Gitea Actions (in-cluster CI):** 30-min opening demo — `git push` to tagged image in Harbor. Argo Workflows / Tekton sidebars. (Close-the-loop callback to ArgoCD lives in the afternoon.) |
| **09:30 - 10:30** | Lecture | The problem with raw YAML. Intro to Helm, `values.yaml`, and Go-templating. (60 min — opens with callback to Tuesday's Kustomize demo: operator vs. publisher.) |
| **10:30 - 10:45** | Break | *15 Minute Morning Break* |
| **10:45 - 12:00** | Lab | **Mission:** Drafting the Blueprint. Templatize the Day 2 app into a Helm Chart. |
| **12:00 - 1:00** | Lunch | *60 Minute Lunch Break* |
| **1:00 - 2:30** | Lecture | Introduction to GitOps (ArgoCD & Gitea). "Git is truth" mentality. |
| **2:30 - 2:45** | Break | *15 Minute Afternoon Break* |
| **2:45 - 4:15** | Lab & Demo | **Mission:** Stand up ArgoCD & Wiring the Archipelago (Clabernetes). **Demo:** JupyterLab deployment. **Closing-loop callback:** ArgoCD picks up the morning's Gitea-Actions-built image — under 60 seconds. |
| **4:15 - 5:00** | AI Connect | **Curiosity Side-Quest:** Update `AGENTS.md` rules for GitOps/Helm; kubectl-delete-pod game; storytime close. |

---

## Day 4: The Admiral's Challenge (Gradable Capstone) — ends 14:30 for airport logistics

| Time | Type | Topic & Activity |
| :--- | :--- | :--- |
| **09:00 - 10:00** | Lecture & Demo | **Cloud-Native Classrooms**: vCluster (5-min named demo), KubeVirt (5-min named demo), Chaos Engineering theory (~50 min). |
| **10:00 - 10:15** | Break | *15 Minute Morning Break (instructor installs Chaos Mesh + applies experiments)* |
| **10:15 - 12:00** | Lab / Game | **Capstone:** The Pirate Strikes! Chaos Mesh is injected. Instructor calls the **Incident Commander persona shift** ~30 min in, when packet loss is most painful. Last ~30 min is Salvage Report drafting with the new persona. Instructor runs `grade-cluster-recovery.sh` per alliance as they declare stability. |
| **12:00** | Submit | **Salvage Reports due** — verified against the rubric in `incident-report-template.md`. |
| **12:00 - 1:00** | Lunch | *60 Minute Lunch Break* |
| **1:00 - 2:15** | Discussion | **Educator's Strategic Roundtable:** "Start, Stop, Continue" Matrix exercise to map modern pedagogy. Includes the AI-context-for-urgency debrief from the morning's persona shift. (75 min — gets the time freed by the shorter trivia.) |
| **2:15 - 2:30** | Wrap-up | K8s / Pedagogy Trivia and Seminar Send-Off (15 min). |
