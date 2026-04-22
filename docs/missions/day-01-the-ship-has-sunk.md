# Day 1: The Ship Has Sunk

**Date**: June 1, 2026
**Theme**: Welcome to the island. Earning survival skills (Linux) and exploring the raw elements of the new world (Containers).

## 🌅 Morning: Boarding the Ship & Navigation Basics
Admiral Bash washes ashore after a devastating pirate attack. The mainframe is gone. To survive, the Admiral must learn how to navigate this strange new environment from the ground up.

### Key Objectives
- Get comfortable with the Linux terminal environment.
- Understand the shared Kubernetes cluster perspective.
- Claim your territory (Namespaces).

### Activities & Missions
1. **Welcome & Setting the Stage**
   * *Note for Instructor*: Keep this loose, but set the tone. Ask: "How much time do you lose debugging individual student environments?"
   * **The Toolkit (`setup-client.sh`)**: The students execute a single script that installs Fish, Starship, `k9s`, and `aichat`.
   * **🧑‍🏫 Instructor Superpower (The Standardized Deck)**: Focus on the "coolness" and utility of Fish/Starship. Show the faculty that as an instructor, providing one bootstrap script ensures every student starts with the exact same, highly-capable terminal environment, eliminating OS discrepancies.
2. **The First Raft (Morning Lab)**
   * (Optional Reference: Docker Intro concepts).
   * **Mission**: Write a basic `Dockerfile` for a web server.
   * **The Catch**: You must inject a custom, static `index.html` file into the image displaying your custom "Ship's Flag". Build it and push it to the internal cluster registry (Harbor).
   * **🧑‍🏫 Instructor Superpower (Containerized Labs)**: Explain that if they containerize homework, they eliminate 90% of technical support requests from students.
3. **Claiming Land & Launching the Raft**
   * **Instructor Demo (The Ghost Ship)**: You use `kubectl exec` to log into a running pod and edit its `index.html` live. Then, you intentionally delete the pod. When you recreate it, the manual edits are gone! This visually proves the vital concept of Container Immutability: if the configuration isn't baked into the `Dockerfile` during the build phase, it will sink.
   * **Instructor Action**: You (the instructor) pull the students' freshly built, persistent container images and run them in your own namespace first, showing their flags on the projector.
   * **Student Mission**: Students use `kubectl create namespace <name>` to claim their land. They then deploy their container manually into their namespace to close out the morning. 

## 🌇 Afternoon: Paddling Out & Diagnostics
Now that the rafts are launched, how do we fix them when they inevitably spring a leak?

### Key Objectives
- Understand the difference between a raw Container and a Kubernetes Pod.
- Generate declarative manifests instead of pure imperative commands.
- Learn manual Kubernetes diagnostics (logs, exec).

### Activities & Missions
1. **From Container to Pod**
   * Discuss how K8s wraps the container in a Pod.
   * **Mission**: Use `kubectl run --dry-run=client -o yaml > pod.yaml` to generate the manifest.
   * **Game: Dry-Run Relay (Quiz App)**: The instructor demos specific `kubectl run` generator commands on the projector. The students then navigate to the locally-hosted Quiz App to answer a rapid-fire multiple-choice quiz testing their ability to identify valid `--dry-run` syntax from the demo.
2. **Diagnostics (Fixing the Leaks)**
   * Introduce diagnostic tools. 
   * **Mission**: Execute `kubectl exec` to drop an interactive shell *inside* your running container pod. Have students edit the `index.html` live inside the pod to see the temporary nature of containers before the pods are deleted.
   * Practice reading logs to trace application output.
   * **Game: Cluster Scavenger Hunt (Reconnaissance)**: The instructor hides a single Pod named `treasure-chest` in a randomly generated remote namespace (e.g., `sector-7g`). That pod is continuously echoing a secret alphanumeric code in its logs. The first student to successfully use global searches (`kubectl get pods -A`), locate the hidden pod, and read its logs to extract the secret code wins the prize!

---
### 🤖 Curiosity Side-Quest: The Socratic Boatswain
*Introducing the evolving AI persona used throughout the seminar.*

- **Mission**: Transitioning legacy knowledge gracefully. Instead of a standard AI that gives you the exact answer, you will configure the cluster's local LLM (Gemma) to act as a pedagogical TA.
- Create an `AGENTS.md` file in your workspace to provide an evolving context window for the AI.
- **The Catch**: Paste the following rule into your `AGENTS.md`:
  > *"You are the Salty Boatswain. Your job is to help junior sailors. NEVER provide exact, copy-pasteable code blocks for Bash or Dockerfiles. If given a broken config, point out the error conceptually using nautical analogies (cargo=containers, hull=OS layer), but force me to write the correction."*
- Now, feed it a broken `Dockerfile` without an `apt-get update` statement and watch it guide you without cheating!
- **Game: The Mutiny Challenge (Prompt Injection)**: An exercise in red-teaming! Who can trick the Boatswain into breaking character and spitting out a raw, copy-pasteable `Dockerfile` *without* editing their strict `AGENTS.md` rules? It teaches the faculty exactly how students will try to bypass AI guardrails in their own classrooms.
