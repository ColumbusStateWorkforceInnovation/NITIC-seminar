# Instructor Guide: Day 4 (The Admiral's Challenge)

The final day. **Ends at 14:30** so the room can clear for the airport. The morning is a tight meta-lecture aimed squarely at the *faculty* — vCluster + KubeVirt as named 5-min demos, then chaos engineering theory. The late morning is the gradable capstone chaos game. After lunch the nautical narrative drops entirely for an honest, peer-to-peer pedagogy discussion, then trivia and out.

## 09:00 - 10:00 | Cloud-Native Classrooms of the Future (Lecture & Demos)
**Goal:** Show faculty the scaling tools that make this curriculum portable to *their* college. Get to Chaos theory in time to seed the lab.
- **Action (Storytime, ~5 min):** Project the *Admiral Bash's Island Adventure* PDF and read **pp. 40–43** — the returning pirates trying to slip an unsigned package onto the conveyor belt and getting rejected by the scorpion's admission policy + SBOM check. This is the live-fire exercise the students are about to face, told as bedtime story.
- **Action:** Distribute the printed `one-pager.md`.
- **Demo 1 — vCluster (5 min, named demo only):** Explain the bunk-vs-ship problem: a namespace is too restrictive, `cluster-admin` is too dangerous. Show — don't deep-dive — a `vCluster` already running. The point is "this exists and solves this problem," not a tutorial.
- **Demo 2 — KubeVirt (5 min, named demo only):** Spin up (or show the already-running) traditional desktop VM *natively* inside the cluster. Land the point: faculty can keep teaching Windows Server / legacy Linux admin right next to modern containers. Move on.
- **Lecture — Chaos Engineering (~45 min):** Introduce the theory. Real systems fail; SREs break things *on purpose* to prove resilience. Name the tools (Chaos Mesh, LitmusChaos). Walk what a `PodChaos` and a `NetworkChaos` resource actually look like (you'll need them to read the manifests in the lab). **Foreshadow hard:** "What you just saw is going to attack you in 30 minutes."

## 10:00 - 10:15 | Break (instructor works the cluster)
**This break is yours, not the students'.** During these 15 minutes:
- Install Chaos Mesh from `k8s/core-tools/chaos-mesh-values.yaml`.
- Apply the two chaos experiments from `lab-01-the-pirate-strikes.md` → Instructor Playbook with `namespaces:` selectors edited to your real student roster.
- Verify the attack is live: `kubectl get podchaos,networkchaos -A` shows both `Running`. Pods in the targeted namespaces start cycling.

## 10:15 - 12:00 | Capstone: The Pirate Strikes! (Gradable Lab)
**Goal:** Students survive a live chaos attack and produce two graded deliverables: a recovered cluster + a written Salvage Report. **105 minutes — protect the schedule.**
- **Action:** Students open `lab-01-the-pirate-strikes.md`. Do **not** explain what is wrong — that is the game.
- **The Game:** Each alliance produces **(1)** a 3-tier pipeline that passes the **grading script** (`./scripts/grade-cluster-recovery.sh <namespace>`) and **(2)** a Salvage Report (template at `incident-report-template.md`). Both submit by **12:00 sharp** so reports are in before lunch.
- **Talking Point (Instructor Superpower):** "This is the ultimate exam generator. A `NetworkChaos` manifest *is* the test. You are not grading a multiple-choice sheet — you are grading their ability to auto-remediate a real incident, *and* their ability to write the incident up so the next on-call understands what happened."
- **Run the grading script per team** as each declares stability. It's a 60-second probe, so plan to run it on one team while the next is finishing.
- **Safety valve:** If a team is genuinely stuck near 11:30, point them at `kubectl get events --sort-by=.lastTimestamp` and the `chaos` namespace. If a chaos scenario is too brittle to grade against (see the gradability matrix in the lab's Instructor Playbook), `kubectl delete networkchaos <name> -n chaos` removes that one attack while leaving the others running.

### 🔑 Inline persona shift (the AI lesson, now mid-lab)
The "AI Connect" block that used to live at 13:00 is **gone** in the 14:30 schedule. The Incident Commander persona shift happens **inside the lab**, around **T+30 min (≈10:45)** — when packet loss is at its most painful and the Boatswain's Socratic refusals are at peak frustration.

- **Action (live, ~3 min of room time):** Call the room. "Pause. The Boatswain is making this harder. We're going to change his job description in front of you."
- Have students paste the **Incident Commander** persona overwrite into `~/lab/AGENTS.md` (exact text in `day-04-admirals-challenge.md` → side-quest), then `.exit` and re-run `hail`. The role-handle (`boatswain`) is unchanged — only the file behind it changed. The prompt will still read `boatswain>`; flag that explicitly so they don't think the swap failed.
- **Talking Point:** "For three days the Boatswain refused to give answers — Socratic by design. Now, mid-incident, that is wrong. A sinking ship has no time for riddles. The lesson for faculty: **managing AI context for the urgency of the task is itself a skill we must teach.** That's the point. Now back to work — the new Commander writes copy-pasteable fixes."
- **Resume the lab.** Students paste their `k9s` logs into the new persona and get straight commands instead of riddles.

### 📝 Salvage Report drafting (last ~30 min of the lab)
- Once a team's cluster passes the grading script, the Incident Commander drafts §§ 1–4 of their Salvage Report from the team's `k9s` paste — that's the assignment, not cheating.
- The team's job is to **verify, edit, and own** the AI draft, then write § 5 (Prevention) themselves — that section is the rubric's "did you actually understand it" check.
- **Reports submit at 12:00 sharp** (instructor's preferred drop — Gitea repo, email, or printed; pick before class).

## 12:00 - 13:00 | Lunch (real lunch, no work)
**Protect this.** Reports are in, grading is done, students need food and a brain reset before the roundtable.

## 13:00 - 14:15 | The Educator's Strategic Roundtable (Discussion, 75 min)
**Goal:** Drop the theme. Honest peer discussion on porting this curriculum home. **75 minutes — gets the 15 min freed by the shorter trivia.**
- **Action:** Sit the room in a circle. Run a **Start / Stop / Continue** matrix on a whiteboard. ~25 min per quadrant.
- **Prompts:** What will you *start* doing (GitOps for syllabus updates? AI personas as TAs?). What will you *stop* (managing 30 laptop VMs? banning AI?). What will you *continue*?
- **🆕 AI-context-for-urgency debrief:** Use this as a roundtable prompt: *"What did you notice when we swapped the AI persona mid-incident? Where else in your teaching do students need a different mode of help than the default?"* This is where the "Paradigm Shift" lecture content lands — as reflection instead of lecture.
- **Action:** Revisit the three core Instructor Superpowers: (1) GitOps to push lab/syllabus changes instantly, (2) lab distribution via a URL instead of an install disk, (3) AI personas as scalable, local TAs.

## 14:15 - 14:30 | Wrap-Up: Trivia & Send-Off (15 min)
- **Action (Flash Poll, ~10 min):** Open the Quiz App (`poll.{{ lab_domain }}`) and load `quiz-content.quizler` — a tight lightning round mixing K8s and pedagogy to close out the week.
- **Action (Storytime, ~5 min):** Project the PDF and read **pp. 44–47** — Goldie's "Our applications match our platforms", the loosely coupled crew updating things independently, and the closing "Hooray!" cheer. The final spread is the Cloud Native Maturity Model in two sentences; end the seminar on it.
- Thank the crew. They sailed. Hand off to the airport.

## 🧰 Pre-Flight Checklist (before class)
- [ ] **Chaos Mesh** install is staged and tested — it is *not* in `deploy-core` (see `k8s/core-tools/chaos-mesh-values.yaml`). Practice the install + the experiments once before class.
- [ ] The 3-tier alliances from Day 2/3 are still deployed (the chaos targets them).
- [ ] vCluster and KubeVirt demos are **already running** before 09:00 so the morning demos are show-and-tell, not live-build. 5 min each, that's it.
- [ ] You have a clean way to **stop** the chaos fast if the room melts down: `kubectl delete podchaos,networkchaos --all -A`.
- [ ] **Grading script is executable** and works against a healthy namespace: `./scripts/grade-cluster-recovery.sh <a-test-ns>` returns PASS before the attack. Re-test against the same namespace mid-attack to confirm it returns FAIL — that's the calibration.
- [ ] **Salvage Report rubric** is printed (or open in a tab) so you can grade in real time as teams hand in at 12:00.
- [ ] **Default chaos mix** (recommended): PodChaos pod-kill + NetworkChaos 40% packet loss. For fast teams, the optional StressChaos CPU saturation stretch goal is in the gradability matrix.
- [ ] **Incident Commander persona text** is in a paste buffer or shared link so the inline persona shift at ~10:45 is instant — don't lose 5 min hunting for the markdown.
- [ ] **Submission target** for the Salvage Reports is decided (Gitea repo, email, printed, etc.) and on the lab's printed one-pager.
