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
| **09:00 - 10:30** | Lecture | Introduction to K8s Architecture, Deployments, and ConfigMaps. `k9s` intro. |
| **10:30 - 10:45** | Break | *15 Minute Morning Break* |
| **10:45 - 12:00** | Lab | **Mission:** Deploying the Fleet. The `k9s` CrashLoopBackOff Speed Round. |
| **12:00 - 1:00** | Lunch | *60 Minute Lunch Break* |
| **1:00 - 2:30** | Lecture | Introduction to Networking, Services, and internal DNS. |
| **2:30 - 2:45** | Break | *15 Minute Afternoon Break* |
| **2:45 - 4:15** | Lab | **Mission:** Fleet Logistics. Forming 3-tier alliances and linking Services across boundaries. |
| **4:15 - 5:00** | AI Connect | **Curiosity Side-Quest:** Update `AGENTS.md` to be the Strict Syllabus Enforcer. |

---

## Day 3: Automated Shipyards (Helm & GitOps)

| Time | Type | Topic & Activity |
| :--- | :--- | :--- |
| **09:00 - 10:30** | Lecture | The problem with raw YAML. Intro to Helm, `values.yaml`, and Go-templating. |
| **10:30 - 10:45** | Break | *15 Minute Morning Break* |
| **10:45 - 12:00** | Lab | **Mission:** Drafting the Blueprint. Templatize the Day 2 app into a Helm Chart. |
| **12:00 - 1:00** | Lunch | *60 Minute Lunch Break* |
| **1:00 - 2:30** | Lecture | Introduction to GitOps (ArgoCD & Gitea). "Git is truth" mentality. |
| **2:30 - 2:45** | Break | *15 Minute Afternoon Break* |
| **2:45 - 4:15** | Lab & Demo | **Mission:** Stand up ArgoCD & Wiring the Archipelago (Clabernetes). **Demo:** JupyterLab deployment. |
| **4:15 - 5:00** | AI Connect | **Curiosity Side-Quest:** Update `AGENTS.md` rules for GitOps/Helm. |

---

## Day 4: The Admiral's Challenge

| Time | Type | Topic & Activity |
| :--- | :--- | :--- |
| **09:00 - 10:30** | Lecture & Demo | **Cloud-Native Classrooms**: Virtualizing clusters (vCluster), deploying legacy VMs natively (KubeVirt), and an intro to Chaos Engineering. |
| **10:30 - 10:45** | Break | *15 Minute Morning Break* |
| **10:45 - 12:00** | Lab / Game | **Mission:** The Pirate Strikes! Chaos Mesh is injected. Students must survive. |
| **12:00 - 1:00** | Lunch | *60 Minute Lunch Break* |
| **1:00 - 2:30** | AI Connect | **The Paradigm Shift**: Rewrite `AGENTS.md` into the Incident Commander to trace the morning attack. |
| **2:30 - 2:45** | Break | *15 Minute Afternoon Break* |
| **2:45 - 4:15** | Discussion | **Educator's Strategic Roundtable:** "Start, Stop, Continue" Matrix exercise to map modern pedagogy. |
| **4:15 - 5:00** | Wrap-up | K8s / Pedagogy Trivia and Seminar Send-Off! |
