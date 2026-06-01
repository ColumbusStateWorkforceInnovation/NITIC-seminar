# Instructor Guide: Day 2 (Meet the Crew)

Day 2 shifts the students from the standard CLI to the visual `k9s` dashboard, and introduces the concept of Services (internal networking). The day ends with a high-stakes group activity.

!!! note "Before 9:00 AM"
    Run the [Namespace Sweep](groups-and-sweep.md#namespace-sweep-day-2-0900-5-min) — diff the roster against the cluster and heal anyone missing before the CrashLoop game runs. The crib sheet also has the [Lab 03 team assignments](groups-and-sweep.md#team-assignments-lab-03-fleet-logistics); call those out at the start of the afternoon block instead of shuffling on the floor.

## 09:00 - 09:10 | Storytime
- **Action:** Project the PDF and read the "Day 2 Morning" passage from `book-readings.md`.
- **Action:** Distribute the printed `one-pager.md`.

## 09:10 - 09:20 | Kustomize (10-min opening demo)
**Goal:** Land one claim before the lecture starts — *the reason your environment shows up in your namespace this week is one file called a Kustomize overlay.*
- **Reference:** [`demo-kustomize.md`](demo-kustomize.md) (run-sheet + pre-flight), slides at [`slides/day-02/kustomize.md`](../../../slides/day-02/kustomize.md), manifests in [`kustomize-demo/`](kustomize-demo/).
- **Pre-flight (night before):** push a `<student-name>:v2` raft image for every student with a visible change (different background/message). Apply the overlay loop at 07:00 so students walk in to `:v2`. Alternative: apply it live at 09:11 with a student's `k9s` on the projector — more dramatic, slightly riskier.
- **Action:** No student keyboards. Walk slides 2–5 (3 min). Show the overlay file in a terminal pane (3 min). Narrate the apply loop (3 min). Hand off.
- **Talking Point:** "Two different problems, two different tools. Kustomize is the operator's tool — same shape, many copies. Helm is the publisher's tool — tomorrow. Today you just need to recognise the shape."
- **Hand off** at 09:20 with the lead slide: *"That's all you need to know about Kustomize today. Captain Kube takes the wheel."*

## 09:20 - 10:30 | The Radar Room (Lecture)
**Goal:** Introduce K8s Architecture and the `k9s` dashboard. **70 min** (was 90; Kustomize demo took 10, storytime already accounted for).
- **Lecture:** Explain the difference between Pods, Deployments, and ConfigMaps.
- **Action (The Trap):** During the break at 10:30, run `./scripts/day-02-crashloop-game.sh`. This secretly deploys a broken `leaky-ship` pod into every single student's namespace. *(Confirm the [namespace sweep](groups-and-sweep.md#namespace-sweep-day-2-0900-5-min) was clean — the injector only hits namespaces that exist.)*

## 10:45 - 12:00 | Lab 01 & 02: Radar Room + Deploying the Fleet
**Goal:** Students learn `k9s`, diagnose the CrashLoopBackOff, and build a resilient Deployment with injected config.
- **CrashLoopBackOff Triage:** Have the students open `k9s` and find their namespace. Tell them a rogue wave has hit their ship. Walk the room as they locate the `leaky-ship` pod, hit `l` for logs, and read the error message (`cat: can't open '/nonexistent/config.txt': No such file or directory`). Have a student share the error with the room when they've read it. The "fix" here is recognising it's an image-level bug they don't control — Lab 01 Step 3/4 then has them delete the Pod (and watch a replacement spawn) before deleting the Deployment proper.
- **Talking Point (Instructor Superpower):** Emphasize how `k9s` changes teaching. Show them how you can type `/` from your laptop at the podium to instantly view *their* namespace, eliminating the need to walk around the classroom looking over shoulders.
- **Action:** Have them complete Lab 02 to generate their Deployments and use `aichat` to build a ConfigMap.

## 01:00 - 02:30 | Drawing the Fleet (Lecture)
**Goal:** Explain Kubernetes Services and internal DNS.
- **Lecture:** How does Pod A talk to Pod B when IP addresses change every time a Pod restarts? Introduce `ClusterIP` and the DNS structure (`<service>.<namespace>.svc.cluster.local`).
- **Action (Flash Poll):** Open the Quiz App (`poll.{{ lab_domain }}`). Load the `quiz-content.quizler` file. Walk the room through the 5 questions; use the results to gauge comprehension.

## 02:45 - 04:15 | Lab 03: Fleet Logistics
**Goal:** A 3-person group activity to wire a Database, Backend, and Frontend together.
- **Action:** Call out the four pre-assigned teams from [groups-and-sweep.md](groups-and-sweep.md#team-assignments-lab-03-fleet-logistics) — Albatross, Barracuda, Cormorant, Dolphin. Each team has A/B/C roles and the teammate namespaces they'll need for DNS strings already listed. They follow `lab-03-fleet-logistics.md` from Step 2.
- **Action (The Code Reviewer):** Ensure they add the "Syllabus Enforcer" rule to `~/lab/AGENTS.md` and re-launch `hail` so the new rule loads. Tell them to ask the Boatswain to review their YAML. The AI will aggressively yell at them if they hardcode IP addresses!
- **Action (The Sabotage):** Once the groups have their 3-tier apps working and are celebrating, secretly execute `./scripts/day-02-network-blockade.sh`.
- **The Twist:** This script deploys a default-deny NetworkPolicy, completely breaking their apps! Watch the confusion. Announce the "Network Blockade". Tell them they must use `hail` (the Boatswain) to figure out what a NetworkPolicy is and write an allow rule to fix the connection. When the first group recovers, have them walk the room through what they changed.

## 04:15 - 05:00 | AI Connect & Debrief
- **Discussion:** Debrief the Network Blockade. Ask the faculty how they felt when the app broke but the Pods were still running perfectly fine. Networking is always the hardest part!
- **Discussion:** Ask how they could use the "Syllabus Enforcer" AI prompt in their own classrooms to automatically grade or review student code before the student submits it.
- **Action (Storytime):** Project the PDF and read the "Day 2 Afternoon" passage from `book-readings.md` to close out the day.
