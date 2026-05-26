# Instructor Guide: Day 4 (The Admiral's Challenge)

The final day. The morning is a meta-lecture aimed squarely at the *faculty* — the most advanced Instructor Superpowers of the week. The late morning is the capstone chaos game. The afternoon drops the nautical narrative entirely for an honest, peer-to-peer pedagogy discussion.

## 09:00 - 10:30 | Cloud-Native Classrooms of the Future (Lecture & Demo)
**Goal:** Show faculty the scaling tools that make this curriculum portable to *their* college.
- **Action (Storytime):** Project the PDF and read the "Day 4 Morning" passage from `book-readings.md`.
- **Action:** Distribute the printed `one-pager.md`.
- **Demo 1 — vCluster:** Explain the bunk-vs-ship problem: a namespace is too restrictive, `cluster-admin` is too dangerous. Demo a `vCluster` — a full, isolated Kubernetes API server inside one namespace. Every student gets a "real" cluster with full admin rights, zero risk to the host.
- **Demo 2 — KubeVirt:** Spin up a traditional desktop VM *natively* inside the cluster. Land the point: faculty can keep teaching Windows Server / legacy Linux admin right next to modern containers, on one unified cluster.
- **Lecture — Chaos Engineering:** Introduce the theory. Real systems fail; SREs break things *on purpose* to prove resilience. Name the tools (Chaos Mesh, LitmusChaos). **Foreshadow:** "Remember this after the next break."

## 10:45 - 12:00 | Lab 01: The Pirate Strikes! (Live Chaos Game)
**Goal:** Students survive a live chaos attack and remediate it under pressure.
- **Action (The Attack):** During the 10:30 break, install Chaos Mesh and apply the chaos experiments (see `lab-01-the-pirate-strikes.md` → Instructor Playbook). Pods start dying; cross-namespace links drop intermittently.
- **Action:** Students open `lab-01-the-pirate-strikes.md`. Do **not** explain what is wrong — that is the game.
- **The Game:** First alliance to (1) trace the root cause to the Chaos manifests and (2) stabilize their 3-tier pipeline takes the Challenge. Watch for teams that panic-delete pods vs. teams that read `kubectl get events`.
- **Talking Point (Instructor Superpower):** "This is the ultimate exam generator. A `NetworkChaos` manifest *is* the test. You are not grading a multiple-choice sheet — you are grading their ability to auto-remediate a real incident."
- **Safety valve:** If a team is genuinely stuck near 11:45, point them at `kubectl get events --sort-by=.lastTimestamp` and the `chaos` namespace.

## 01:00 - 02:30 | The Paradigm Shift (AI Connect)
**Goal:** The capstone AI lesson — context management as a teachable skill.
- **Action:** Have students **completely overwrite** their `AGENTS.md` with the *Incident Commander* persona (exact text in `day-04-admirals-challenge.md` → side-quest).
- **Talking Point:** For three days the Boatswain refused to give answers — Socratic by design. Now, mid-incident, that is wrong. A sinking ship has no time for riddles. The lesson for faculty: **managing AI context for the urgency of the task is itself a skill we must teach.**
- **Action:** Have students paste their morning `k9s` logs into the new Incident Commander and watch it cut straight to copy-pasteable fixes.

## 02:45 - 04:15 | The Educator's Strategic Roundtable (Discussion)
**Goal:** Drop the theme. Honest peer discussion on porting this curriculum home.
- **Action:** Sit the room in a circle. Run a **Start / Stop / Continue** matrix on a whiteboard.
- **Prompts:** What will you *start* doing (GitOps for syllabus updates? AI personas as TAs?). What will you *stop* (managing 30 laptop VMs? banning AI?). What will you *continue*?
- **Action:** Revisit the three core Instructor Superpowers: (1) GitOps to push lab/syllabus changes instantly, (2) lab distribution via a URL instead of an install disk, (3) AI personas as scalable, local TAs.

## 04:15 - 05:00 | Wrap-Up: Trivia & Send-Off
- **Action (Flash Poll):** Open the Quiz App (`poll.{{ lab_domain }}`) and load `quiz-content.quizler` — a lightning round mixing K8s and pedagogy to close out the week.
- **Action (Storytime):** Project the PDF and read the "Day 4 Afternoon" passage from `book-readings.md` to close the seminar.
- Thank the crew. They sailed.

## 🧰 Pre-Flight Checklist (before class)
- [ ] **Chaos Mesh** install is staged and tested — it is *not* in `deploy-core` (see `k8s/core-tools/chaos-mesh-values.yaml`). Practice the install + the experiments once before class.
- [ ] The 3-tier alliances from Day 2/3 are still deployed (the chaos targets them).
- [ ] vCluster and KubeVirt demos are rehearsed and the demo manifests are ready.
- [ ] You have a clean way to **stop** the chaos fast if the room melts down: `kubectl delete podchaos,networkchaos --all -A`.
