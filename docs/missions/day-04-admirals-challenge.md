# Day 4: The Admiral's Challenge

**Date**: June 4, 2026
**Theme**: Putting it all together. The Pirate strikes, and the fleet must endure the chaos to prove they are ready to sail alone.

## 🌅 Morning: Cloud-Native Classrooms of the Future

Before the ultimate challenge begins, Admiral Bash shares some of the most advanced maneuvers in the fleet. This is a meta-lecture dedicated specifically towards Instructor Superpowers.

### Key Objectives
- Understand how to scale the classroom securely.
- Bridge the gap between legacy curriculum (VMs) and modern clusters (K8s).
- Understand the theory of Chaos Engineering before it attacks us!

### Activities & Missions
1. **Virtualizing the Classroom (`vCluster`)**
   - **Lecture**: Giving a student a Kubernetes namespace is like giving them a bunk on a ship—they are extremely restricted. Giving them `cluster-admin` risks sinking the entire host. 
   - **🧑‍🏫 Instructor Superpower**: `vCluster` deploys a *full, isolated Kubernetes API server* inside a single namespace. To the student, it looks and feels like an entire multi-node cluster where they have full `cluster-admin` privileges. It is the absolute best way to give 30 students "full" K8s clusters without actually buying/provisioning 30 independent clusters.
2. **The Legacy Fleet (`KubeVirt` Demo)**
   - **Lecture & Demo**: Faculty often hesitate to adopt Kubernetes because they still need to teach Windows Server, Active Directory, or legacy Linux administration.
   - **🧑‍🏫 Instructor Superpower**: **KubeVirt** wraps standard QEMU/KVM virtual machines inside Kubernetes Pods. The instructor will spin up a traditional desktop VM natively inside the Kubernetes cluster. The VM shares the EXACT same virtual network as our Day 2 web-pods. You can teach legacy network administration right next to modern Docker containers on the same unified cluster. Hardcore IT programs use this to transition fully to K8s without losing their legacy labs!
3. **Introduction to Chaos Engineering**
   - **Lecture**: Real-world systems fail. We use tools like Chaos Mesh and LitmusChaos to intentionally break our clusters to test their resilience, a practice heavily used in Site Reliability Engineering (SRE).
   - **🧑‍🏫 Instructor Superpower**: The ultimate exam generator. Instead of a multiple-choice test, an instructor can deploy a `NetworkChaos` manifest via GitOps that drops 50% of a student's packets, or violently kills their database, grading them entirely on their ability to auto-remediate the issue!

## ⚔️ Late Morning: The Grand Admiral Challenge

The theoretical discussions are interrupted. A Pirate has infiltrated the Git repositories and cluster!

### Activities & Missions
1. **The Pirate Strikes! (Live Chaos Game)**
   - The instructor installs a CNCF Chaos Engineering platform (**Chaos Mesh**) into the cluster.
   - **The Game**: The Pirate deploys an active chaos experiment that randomly severs cross-namespace communication and kills web server pods within the 3-Tier alliances. The first team to trace the root cause and fully stabilize their logistics pipeline wins!
2. **Restoring the Fleet**
   - **Group Mission**: Work together across your 3-Tier alliances to stabilize the grid while actively under attack.
   - What is happening?! Students must use `k9s` and `kubectl get events` to trace the intermittent failures back to the Chaos manifests discussed in the morning lecture.
   - Once identified, the students must defend their namespaces—either by creating targeted `NetworkPolicies` to block the Pirate's Chaos Mesh agent, or by submitting a GitOps PR to restrict the chaos.
3. **Admiral's Review & The Educator's Roundtable**
   * Post-incident review: Discuss the sheer resilience of Kubernetes. While Chaos Mesh killed pods, the Deployments and ArgoCD constantly fought to heal the system.
   * **The Strategic Educator's Roundtable**: Drop the nautical narrative for the final 45 minutes. Sit in a circle and discuss how the faculty can port this curriculum back to their colleges. Review the three core "Instructor Superpowers" learned this week:
     1. **Updating Classes**: Using GitOps to push syllabus/lab changes instantly.
     2. **Lab Distribution**: Giving students a URL to a containerized JupyterLab instead of an install disk.
     3. **AI at Scale**: Engineering LLM personas to act as local, automated TAs.
   * **Games & Prizes**: Lightning round of K8s / Pedagogy Trivia to distribute the final batch of sweet Swag.

---
### 🤖 Curiosity Side-Quest: The AI Incident Commander
*The Paradigm Shift: From Socratic Tutor to War-Room Chief.*

- **Mission**: For three days, you trained the AI to be a strict Socratic Tutor refusing to give answers. Now, we are under active Pirate attack. A sinking ship has no time for riddles!
- Completely overwrite your `AGENTS.md` with:
  > *"Final Mission: The Socratic learning phase is over. We are under active Pirate attack. I am the Incident Commander, you are my Chief of Staff. I have no time for hints or riddles. When I paste `k9s` logs or ArgoCD error states: 1) State the probable root cause in precisely ONE sentence. 2) Provide the EXACT, copy-pasteable `kubectl` command or YAML patch required to stop the bleeding. Do not say 'you could try', give me the command."*
- **The Catch**: The instructors just learned that they aren't just teaching students *how to code*; they are teaching students *how to manage AI context depending on the urgency of the task at hand*. Watch the LLM instantly cut through the Chaos Mesh noise!

---
**Congratulations, Admirals.** Have a safe journey home!
