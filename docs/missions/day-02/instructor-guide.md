# Instructor Guide: Day 2 (Meet the Crew)

Day 2 shifts the students from the standard CLI to the visual `k9s` dashboard, and introduces the concept of Services (internal networking). The day ends with a high-stakes group activity.

## 09:00 - 10:30 | The Radar Room (Lecture)
**Goal:** Introduce K8s Architecture and the `k9s` dashboard.
- **Action (Storytime):** Project the PDF and read the "Day 2 Morning" passage from `book-readings.md`.
- **Action:** Distribute the printed `one-pager.md`.
- **Lecture:** Explain the difference between Pods, Deployments, and ConfigMaps. 
- **Action (The Trap):** During the break at 10:30, run `./scripts/day-02-crashloop-game.sh`. This secretly deploys a broken `leaky-ship` pod into every single student's namespace.

## 10:45 - 12:00 | Lab 01 & 02: Deploying the Fleet
**Goal:** Students learn `k9s` and fix the CrashLoopBackOff error.
- **Game (CrashLoop Speed Round):** Have the students open `k9s` and find their namespace. Tell them a rogue wave has hit their ship. The first student to find the `leaky-ship` pod, hit `l` for logs, and shout out the error message (`cat: can't open '/nonexistent/config.txt': No such file or directory`) wins the prize!
- **Talking Point (Instructor Superpower):** Emphasize how `k9s` changes teaching. Show them how you can type `/` from your laptop at the podium to instantly view *their* namespace, eliminating the need to walk around the classroom looking over shoulders.
- **Action:** Have them complete Lab 02 to generate their Deployments and use `aichat` to build a ConfigMap.

## 01:00 - 02:30 | Drawing the Fleet (Lecture)
**Goal:** Explain Kubernetes Services and internal DNS.
- **Lecture:** How does Pod A talk to Pod B when IP addresses change every time a Pod restarts? Introduce `ClusterIP` and the DNS structure (`<service>.<namespace>.svc.cluster.local`).
- **Action (Flash Poll):** Open the Quiz App (`poll.{{ lab_domain }}`). Load the `quiz-content.quizler` file. Have the students race to answer the 5 questions.

## 02:45 - 04:15 | Lab 03: Fleet Logistics
**Goal:** A 3-person group activity to wire a Database, Backend, and Frontend together.
- **Action:** Put students into groups of 3. They must follow `lab-03-fleet-logistics.md`.
- **Action (The Code Reviewer):** Ensure they add the "Syllabus Enforcer" rule to their `AGENTS.md`. Tell them to ask the AI to review their YAML. The AI will aggressively yell at them if they hardcode IP addresses!
- **Action (The Sabotage):** Once the groups have their 3-tier apps working and are celebrating, secretly execute `./scripts/day-02-network-blockade.sh`.
- **The Twist:** This script deploys a default-deny NetworkPolicy, completely breaking their apps! Watch the confusion. Announce the "Network Blockade". Tell them they must use `aichat` to figure out what a NetworkPolicy is and write an allow rule to fix the connection. The first group to recover wins a prize!

## 04:15 - 05:00 | AI Connect & Debrief
- **Discussion:** Debrief the Network Blockade. Ask the faculty how they felt when the app broke but the Pods were still running perfectly fine. Networking is always the hardest part!
- **Discussion:** Ask how they could use the "Syllabus Enforcer" AI prompt in their own classrooms to automatically grade or review student code before the student submits it.
- **Action (Storytime):** Project the PDF and read the "Day 2 Afternoon" passage from `book-readings.md` to close out the day.
