# 🌊 Curriculum Deep Dive: "Admiral Bash's Island Adventure"
*Prepared for Stakeholder Review*

## 1. The Pedagogical Vision
This 4-day DevOps intensive departs from traditional "death-by-PowerPoint" IT training. It fuses a lightweight nautical narrative (Admiral Bash) with an aggressive focus on **Instructor Superpowers**. The primary goal is not just to teach Kubernetes to visiting faculty, but to convince them that Cloud-Native architectures are the *superior method for running their own classrooms*.

### The Infrastructure Foundation
Instead of relying on fragile local Virtual Machines (VMs) on student laptops, the entire 30-person seminar is hosted on **One Giant Shared K3d Cluster** (backed by an Azure A100 GPU instance). Students access their environments entirely via SSH/CLI. This centralized model allows the instructor to globally monitor, reset, and inject chaos into student assignments instantly.

---

## 2. Daily Mission Breakdown

### 🌅 Day 1: The Ship Has Sunk (Fundamentals & Immutability)
**Technical Arc:** Linux/Fish Basics → Docker Containers → Raw K8s Pods.
**The Instructor Superpowers:**
* **The Standardized Deck:** Using `setup-client.sh` to give everyone identical Fish terminal abbreviations, eliminating OS debugging.
* **The Ghost Ship Demo:** A powerful visual demonstration of container immutability. The instructor edits a live web server, deletes the pod, and watches the edits vanish—proving why declarative `Dockerfiles` are mandatory.
* **The AI Side-Quest (Prompt Injection):** We introduce the local, cluster-hosted **Gemma4** model as the "Socratic Boatswain." Faculty play a red-teaming game to trick the AI into giving them the answers, learning firsthand how their students will attempt to bypass LLM guardrails.

### ⚙️ Day 2: Meet the Crew (Orchestration & Alliances)
**Technical Arc:** Deployments → ConfigMaps → Services (Internal DNS)
**The Instructor Superpowers:**
* **The `k9s` Speed Round:** Instructors learn to use `k9s` to monitor the entire classroom from the podium. The day features a live game where the instructor deliberately injects a `CrashLoopBackOff` error into the students' namespaces; the first to diagnose it wins a book copy.
* **Fleet Logistics (Group Work):** Students form 3-person alliances to build a 3-tier microservice. If Student A configures their database Service DNS incorrectly, Student C's frontend immediately breaks. It forces real cross-team communication boundaries.

### 🏗️ Day 3: Automated Shipyards (Scale & GitOps)
**Technical Arc:** Helm (Templating) → Gitea/Harbor (CI) → ArgoCD (GitOps) → Clabernetes
**The Instructor Superpowers:**
* **The JupyterLab Distribution:** A live demo proving that by committing a Helm chart to Git, ArgoCD instantly deploys 30 heavy data-science environments across the classroom without a single USB drive.
* **Wiring the Archipelago (Network-as-Code):** Traditional IT faculty struggle to teach networking without massive VM overhead (e.g., GNS3). We introduce **Clabernetes**, demonstrating how to spin up commercial Cisco/Nokia routers natively as K8s Pods, allowing students to configure BGP/OSPF directly from their terminal.

### ⚔️ Day 4: The Admiral's Challenge (Chaos & Resilience)
**Technical Arc:** vCluster → KubeVirt → Chaos Mesh
**The Instructor Superpowers:**
* **The Meta-Lecture:** The morning begins with a deep dive into advanced classroom scaling. We demonstrate **vCluster** (giving students isolated `cluster-admin` sandboxes) and **KubeVirt** (running legacy Windows VMs natively alongside Docker containers).
* **The Pirate Strikes (Live Chaos Game):** We replace the final multiple-choice exam with a live **Chaos Mesh** attack. The "Pirate" randomly severs student networks and kills web pods. The faculty are graded entirely on how fast they can trace the root cause and patch their declarative manifests to survive the attack.

---

## 3. Logistics & Gamification Integration
The intensive is designed to maintain high engagement through integrated gamification. Rather than handing out swag randomly, the 7+ book copies (*Admiral Bash's Island Adventure*) and Credly badges are tied to specific daily victories:
1. Surviving the Day 1 *Ghost Ship* Immutability trap.
2. Winning the Day 2 *k9s* CrashLoopBackOff hunt.
3. The Day 3 *Helm Templating* speed run.
4. The first Alliance to stabilize their grid during the Day 4 *Chaos Mesh* attack.
