# Day 2: Meet the Crew

**Date**: June 2, 2026
**Theme**: Expanding our view. Meeting Captain Kube, organizing the cluster, and connecting our fleet with Linky.

## 🌅 Morning: Captain Kube & The Radar Room
Bash meets Captain Kube, who keeps the island organized. If we are going to rule the waves, we have to understand how to monitor them.

### Key Objectives
- Understand Kubernetes architecture (Deployments, Pods, ConfigMaps).
- Navigate the cluster seamlessly.
- Transition from basic Pods to resilient Deployments using manual `kubectl`.



### Activities & Missions
1. **The Radar Room**
   * (Optional Reference: Intro to Kubernetes Architecture slides).
   * Introduce `k9s` for TUI-based visualization and cluster administration.
   * Learn how to filter by namespace, view logs, and exec into pods.
   * **Game**: *k9s Speed Round*. The instructor deliberately injects a broken Deployment (`CrashLoopBackOff`) into everyone's namespace. The first student to find it using `k9s` and read the logs to diagnose the issue wins a book copy!
   * **🧑‍🏫 Instructor Superpower (The Teacher's Dashboard)**: Once students learn `k9s`, instructors realize its true power: they never have to look over a student's shoulder again. Just type `/` and the student's namespace in `k9s` to instantly monitor their progress or debug their errors from the front of the room.
2. **Deploying the Fleet (Mission)**
   * Build on Day 1: Instead of a standalone Pod, create a `Deployment` for your ship's web server to ensure high availability.
   * Add a `ConfigMap` containing an environment variable (like `SHIP_SPEED` or `MESSAGE_OF_THE_DAY`). Inject this ConfigMap into your Deployment so your web server container prints it out. Apply these natively with `kubectl apply`.

## 🌇 Afternoon: Drawing the Fleet & Cross-Communication
No ship sails alone. It's time to meet Linky (Services) and establish interconnectivity across student boundaries.

### Key Objectives
- Understand internal Services (ClusterIP, NodePort) for routing traffic.
- Experience group collaboration via cross-namespace dependencies.
- Map the architecture using D2 diagram-as-code.

### Activities & Missions
1. **Meet Linky (Kubernetes Services)**
   * (Optional Reference: Kubernetes Objects/Services slides).
   * Discuss how pods are ephemeral and how Services provide a stable anchor.
2. **Group Activity: Fleet Logistics (The 3-Tier Dependency)**
   * **Mission**: Expose your deployment using a Kubernetes Service so others can access it.
   * **The Catch**: You will form alliances in groups of 3 to deploy a functional 3-tier application ecosystem across distinct namespaces.
   * *Instructor Note*: Provide the pre-built Docker Images for the complex tiers (Redis, Go-Backend, React-Frontend). The students' entire focus is securely writing the `Deployment` and `Service` YAMLs to wire them together.
     * **Student A (The Storehouse)**: Writes the YAML for the Stateful database/cache.
     * **Student B (The Ledger)**: Writes the YAML for the Backend REST API, configuring its environment variable to target Student A's `Service` across the cluster boundary.
     * **Student C (The Radar)**: Writes the YAML for the Web Frontend UI, configuring it to fetch data from Student B's Backend API Service.
   * If any student uses the wrong internal DNS formatting (`http://service.namespace.svc.cluster.local`), the entire logistical chain breaks!
   * **🧑‍🏫 Instructor Superpower (The Collaborative Classroom)**: Services aren't just for code; they are for group projects. Instructors can use internal DNS to force real-life dependencies among students, mimicking real cross-team microservice development. If Student A's database fails, Student C's dashboard breaks!

---
---
### 🤖 Curiosity Side-Quest: The AI Code Reviewer
*Evolving the Socratic Boatswain `AGENTS.md` context.*

- **Mission**: Have the AI aggressively critique your adherence to the syllabus rules without actually solving the problem for you.
- Append the following `Rule Update 2` to your `AGENTS.md` file:
  > *"When reviewing Kubernetes YAML, NEVER tell me if it works or not. Instead, violently critique my YAML based on this strict class rule: Did I use a hardcoded IP address? If so, demand I use a Service. Explain why hardcoded IPs sink ships."*
- **The Catch**: You just turned your LLM into an automated syllabus enforcer! Imagine giving this to your students so the AI catches basic requirement misses *before* they ask you a question.
