# Instructor Guide: Day 2 (Meet the Crew)

Day 2 shifts the students from the standard CLI to the visual `k9s` dashboard, and introduces the concept of Services (internal networking). The day ends with a high-stakes group activity.

!!! note "Before 9:00 AM"
    Run the [Namespace Sweep](groups-and-sweep.md#namespace-sweep-day-2-0900-5-min) — diff the roster against the cluster and heal anyone missing before the CrashLoop game runs. The crib sheet also has the [Lab 03 team assignments](groups-and-sweep.md#team-assignments-lab-03-fleet-logistics); call those out at the start of the afternoon block instead of shuffling on the floor.

## 09:00 - 09:10 | Storytime + Day 1 Quiz Warm-up
- **Action (Storytime, ~2 min):** Project the *Admiral Bash's Island Adventure* PDF and read **pp. 8–11** — Captain Kube guiding the penguins as "they knew exactly what they should be doing", Goldie and the kube-cuttlefish helping deploy the first mapping app. This is the perfect lead-in to Deployments + k9s.
- **Action:** Distribute the printed `one-pager.md`.
- **Action (Day 1 Quiz, 5–7 min):** Day 1's flash poll didn't run yesterday. Open `poll.{{ lab_domain }}` and load `../day-01/quiz-content.quizler`. Run the 5 questions as a warm-up / Day 1 recap. Keep it brisk — use the results to spot any topic that needs a 60-second reset before the Kustomize demo.

## 09:10 - 09:40 | 🚨 Day 1 Catch-Up Block (Lab 01 push, Lab 02 kubectl, Treasure Hunt)
**Why this block exists:** yesterday's Harbor login + Rancher/kubectl access broke for the room. The Harbor robot login is **fixed as of 2026-06-01 PM** — students can `docker push` again. We did *not* get through Lab 02 (kubeconfig, Ghost Ship, scavenger hunt) — finish those here before starting Kustomize. The Kustomize demo / Radar Room lecture pick up at **09:40** (10 min later than original plan; trim 5 min from each lecture if needed).

- **Action — Harbor push catch-up (~5 min):** Have anyone whose Lab 01 push failed yesterday open `~/lab/`, re-run `docker login harbor.{{ lab_domain }}` if they get prompted (the shared robot creds are now baked into `setup-client.sh`), then `docker push harbor.{{ lab_domain }}/raft-fleet/<your-name>:v1`. Project your admiral Harbor view (`harbor.{{ lab_domain }}` → `raft-fleet` project) and name-check each new image as it lands — same payoff moment as yesterday, just shifted a day.
- **Action — Cluster onboarding (Lab 02 §"Board the Cluster", ~10 min):** Walk the room through Lab 02's opening — `https://rancher.{{ lab_domain }}` → Copy KubeConfig → `~/.kube/config` → `kubectl get ns`. Anyone whose `kubectl get ns` errors gets flagged immediately; the rest of Day 2 needs cluster access.
- **Action — Lab 02 Steps 1–3 (~10 min):** Have them claim their `student-<name>` namespace, set it as the default context, generate `pod.yaml` with `kubectl run ... --dry-run=client -o yaml`, apply it, then do the **Ghost Ship** exec-and-edit demo. The Ghost Ship demo from the original Day 1 plan (`scripts/instructor-demo-setup.sh` — instructor-demo namespace) still works — run it on the projector if you didn't get to it yesterday.
- **Action — Treasure Hunt (~5 min, replaces Lab 02 Step 4):** Quietly run `./scripts/day-01-scavenger-hunt.sh` from your terminal while students are still applying their pods. Announce that a `treasure-chest` Pod is hidden in a random secret namespace and the first student to share the 6-character code from its logs wins the room. Hint: `kubectl get pods -A` + `kubectl logs -n <ns> treasure-chest`.
- **Hand off** at 09:40: "That closes Day 1. From here we're meeting Captain Kube properly." Lead into Kustomize.



## 09:40 - 09:50 | Kustomize (10-min opening demo) — *was 09:10; shifted by Day 1 catch-up block above*
**Goal:** Land one claim before the lecture starts — *the reason your environment shows up in your namespace this week is one file called a Kustomize overlay.*
- **Reference:** [`demo-kustomize.md`](demo-kustomize.md) (run-sheet + pre-flight), slides at [`slides/day-02/kustomize.md`](../../../slides/day-02/kustomize.md), manifests in [`kustomize-demo/`](kustomize-demo/).
- **Pre-flight (night before):** push a `<student-name>:v2` raft image for every student with a visible change (different background/message). Apply the overlay loop at 07:00 so students walk in to `:v2`. Alternative: apply it live at 09:11 with a student's `k9s` on the projector — more dramatic, slightly riskier.
- **Action:** No student keyboards. Walk slides 2–5 (3 min). Show the overlay file in a terminal pane (3 min). Narrate the apply loop (3 min). Hand off.
- **Talking Point:** "Two different problems, two different tools. Kustomize is the operator's tool — same shape, many copies. Helm is the publisher's tool — tomorrow. Today you just need to recognise the shape."
- **Hand off** at 09:50 with the lead slide: *"That's all you need to know about Kustomize today. Captain Kube takes the wheel."*

## 09:50 - 10:30 | The Radar Room (Lecture)
**Goal:** Introduce K8s Architecture and the `k9s` dashboard. **40 min** (was 70; the Day 1 catch-up block took 30). Trim hard — drop the optional ConfigMap deep dive; Lab 02 surfaces it organically.
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
- **Action (Storytime, ~2 min):** Project the PDF and read **pp. 24–27** to close out the day — Linky the Lobster stringing strong, secure ropes between the settlements and the encrypted-shell handoff between lobsters and the Saharan Silver Ant. It maps directly onto what students just built: Services as named, reliable lines between Pods that come and go.
