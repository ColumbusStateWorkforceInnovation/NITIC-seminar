# Instructor Guide: Day 4 (The Admiral's Challenge)

The final day. **Ends at 14:30** so the room can clear for the airport. The morning opens with **Make It Your Own** — a fork-and-reuse tour of the repo — then a tight meta-lecture aimed squarely at the *faculty*: vCluster + KubeVirt as named demos and chaos engineering theory. The late morning is the gradable capstone chaos game. After lunch the nautical narrative drops entirely for an honest, peer-to-peer pedagogy discussion, then trivia and out.

## 09:00 - 09:25 | Make It Your Own (Lecture & Demo)
**Goal:** Hand the faculty the keys. Reframe the whole week: the real takeaway is a public, forkable git repo that produces this entire seminar — slides, missions, cluster, and AI mate. By 09:25 every instructor knows what to open first to run (or remix) this at their own college.

- **Action:** Distribute the printed **Repo Cheat Sheet** (`repo-cheatsheet.md`) — every command on the slides is on that page.
- **Slides:** [`slides/day-04/make-it-your-own.md`](../../../slides/day-04/make-it-your-own.md) (~20 slides, slides-led). Deep reference for forkers: the [Make It Your Own](../../make-it-your-own.md) guide.
- **The spine (don't deep-dive any one piece):** the repo *is* the takeaway → the map → `lab.env` (the one knob: blank = local k3d, set = remote server) → the `justfile` (the whole lab as commands) → the toolbox (every service is swappable) → curriculum in `docs/` (MkDocs) → slides are Marp markdown (`just slides`) → the `AGENTS.md` persona (rewrite the file = rewrite the TA; the Incident Commander swap they'll see at the capstone is the proof) → reuse in parts → the fork workflow.
- **Talking Point:** "For three days you were students in this curriculum. The real deliverable was never the slides — it's the repository that produces all of it. Fork it tonight; take the whole ship or just one plank."
- **Bridge:** close on the wink — *"you now have permission to take the whole ship… which is the perfect setup for a game about defending it"* — and hand straight into the Arsenal.

## 09:25 - 10:10 | Cloud-Native Classrooms of the Future (Lecture & Demos)
**Goal:** Show faculty the scaling tools that make this curriculum portable to *their* college. Get to Chaos theory in time to seed the lab. **~45 min — Make It Your Own took the first 25, so keep the two demos to show-and-tell and Chaos theory to ~30 min.**

- **Action (Storytime, ~5 min):** Project the *Admiral Bash's Island Adventure* PDF and read **pp. 40–43** — the returning pirates trying to slip an unsigned package onto the conveyor belt and getting rejected by the scorpion's admission policy + SBOM check. This is the live-fire exercise the students are about to face, told as bedtime story.
- **Action:** Distribute the printed `one-pager.md`.
- **Demo 1 — vCluster (5 min, named demo only):** Explain the bunk-vs-ship problem: a namespace is too restrictive, `cluster-admin` is too dangerous. Show — don't deep-dive — a `vCluster` already running. The point is "this exists and solves this problem," not a tutorial.
- **Demo 2 — KubeVirt (5 min, named demo only):** Spin up (or show the already-running) traditional desktop VM *natively* inside the cluster. Land the point: faculty can keep teaching Windows Server / legacy Linux admin right next to modern containers. Move on.
- **Lecture — Chaos Engineering (~30 min):** Introduce the theory. Real systems fail; SREs break things *on purpose* to prove resilience. Name the tools (Chaos Mesh, LitmusChaos). Walk what a `PodChaos` and a `NetworkChaos` resource actually look like (you'll need them to read the manifests in the lab). **Foreshadow hard:** "What you just saw is going to attack you right after the break."

## 10:10 - 10:25 | Break (instructor works the cluster)
**This break is yours, not the students'.** The whole attack is three recipes — no hand-edited YAML. During these 15 minutes:

```bash
just clear-decks          # optional — free namespace quota if Day-3 leftovers linger
just deploy-chaos-mesh    # installs Chaos Mesh + the `chaos` namespace
just normalize-repos      # Pirate force-pushes the FRAGILE island-stack to every crew's maindeck
just chaos-strike         # recurring pod-kill + pod-failure on every student namespace
```

- `normalize-repos` resets every crew to one identical fragile baseline (1 replica, readiness off, tight CPU limit) and guarantees each has a self-healing `<crew>-stack` ArgoCD Application — so no team is stuck without an app, and grading is deterministic.
- Verify the attack is live: `just chaos-status` shows the `kraken-pod-kill-*` and `kraken-pod-failure-*` Schedules `Running`. Pods in the targeted namespaces start cycling.
- Kill switch, any time: `just chaos-calm`.

## 10:25 - 12:00 | Capstone: The Pirate Strikes! (Gradable Lab)
**Goal:** Students survive a live chaos attack and produce two graded deliverables: a recovered cluster + a written Salvage Report. **95 minutes — protect the schedule.**

- **Action:** Students open `lab-01-the-pirate-strikes.md`. Do **not** explain what is wrong — that is the game.
- **The Game:** Each alliance produces **(1)** a 3-tier pipeline that passes the **grading script** (`./scripts/grade-cluster-recovery.sh <namespace>`) and **(2)** a Salvage Report (template at `incident-report-template.md`). Both submit by **12:00 sharp** so reports are in before lunch.
- **Talking Point (Instructor Superpower):** "This is the ultimate exam generator. A `NetworkChaos` manifest *is* the test. You are not grading a multiple-choice sheet — you are grading their ability to auto-remediate a real incident, *and* their ability to write the incident up so the next on-call understands what happened."
- **Run the grading script per team** as each declares stability. It's a 60-second probe, so plan to run it on one team while the next is finishing.
- **Safety valve:** If a team is genuinely stuck near 11:30, point them at `kubectl get events --sort-by=.lastTimestamp` and the `chaos` namespace. If a chaos scenario is too brittle to grade against (see the gradability matrix in the lab's Instructor Playbook), `kubectl delete networkchaos <name> -n chaos` removes that one attack while leaving the others running.

### 🔑 Inline persona shift (the AI lesson, now mid-lab)
The "AI Connect" block that used to live at 13:00 is **gone** in the 14:30 schedule. The Incident Commander persona shift happens **inside the lab**, around **T+30 min (≈10:55)** — when packet loss is at its most painful and the Boatswain's Socratic refusals are at peak frustration.

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

- [ ] **Repo Cheat Sheet** (`repo-cheatsheet.md`) is printed for the room, and the **Make It Your Own** deck (`slides/day-04/make-it-your-own.md`) is rendered and open for the 09:00 opener.
- [ ] **Chaos Mesh + the attack recipes** are rehearsed once end-to-end (`just deploy-chaos-mesh` → `normalize-repos` → `chaos-strike` → `chaos-calm`). Chaos Mesh is *not* in `deploy-core`.
- [ ] **`normalize-repos` works against your live Gitea** — it pushes over `https://gitea.{{ lab_domain }}` as admin and needs `GITEA_ADMIN_PASSWORD` in `lab.env`. Spot-check one crew afterward: `maindeck` shows the fragile chart and `<crew>-stack` is Synced + Healthy.
- [ ] Each crew has an `island-stack` repo (Day-3 Lab-02); `normalize-repos` creates one for anyone who skipped it, so this is belt-and-suspenders.
- [ ] **ArgoCD poll lag:** there's no Gitea→ArgoCD webhook, so a student's `git push` won't sync for up to ~3 min unless they hit **Refresh/Sync** in the ArgoCD UI (the lab tells them to). If you want the GitOps loop to feel instant, either add a Gitea push webhook to `https://argocd.{{ lab_domain }}/api/webhook` or lower ArgoCD's reconciliation timeout in `k8s/core-tools/argocd-values.yaml` and `just deploy-argocd` before class. Verified end-to-end on the remote server 2026-06-04 (the push→sync loop works; only the latency needs the Refresh click).
- [ ] vCluster and KubeVirt demos are **already running** before 09:00 so the morning demos are show-and-tell, not live-build. 5 min each, that's it.
- [ ] You have a clean way to **stop** the chaos fast if the room melts down: `just chaos-calm`.
- [ ] **Grade with `just grade <crew>`** (e.g. `just grade blackbeard`), NOT a bare `./scripts/grade-cluster-recovery.sh` — the raw script uses your laptop's kubectl, which points at the local k3d and reports a misleading "namespace not found." `just grade` copies it to + runs it on the class server. Names are auto-derived (`<crew>-frontend` / `<crew>-stack`). Run it mid-attack on a normalized-but-unhardened crew to confirm **FAIL** on Gate 2 — that's the calibration — then on a hardened one to see PASS.
- [ ] **Salvage Report rubric** is printed (or open in a tab) so you can grade in real time as teams hand in at 12:00.
- [ ] **Default chaos mix** (`just chaos-strike`): recurring PodChaos pod-kill (exposes single replica) + pod-failure (exposes missing readiness probe). For fast/bored teams, the optional `just chaos-stress` CPU-saturation escalation (exposes the tight CPU limit).
- [ ] **Incident Commander persona text** is in a paste buffer or shared link so the inline persona shift at ~10:45 is instant — don't lose 5 min hunting for the markdown.
- [ ] **Submission target** for the Salvage Reports is decided (Gitea repo, email, printed, etc.) and on the lab's printed one-pager.
