# Day 1: The Ship Has Sunk

**Date**: June 1, 2026
**Theme**: Welcome to the island. Earning survival skills (Linux) and exploring the raw elements of the new world (Containers).

## 🌅 Morning: Building Your Vessel
Admiral Bash washes ashore after a devastating pirate attack. The mainframe is gone. Before the Admiral can learn *anything*, there must be a ship to stand on — so the entire morning is spent forging one: a Linux virtual machine, identical for every sailor in the crew.

### Key Objectives
- Build an Ubuntu VM from scratch in VirtualBox (pre-installed on the classroom desktops).
- Run a single bootstrap script that installs the whole DevOps toolkit.
- Verify the vessel is seaworthy before the labs begin.

### Activities & Missions
1. **Welcome & Setting the Stage**
   * *Note for Instructor*: Keep this loose, but set the tone. Ask: "How much time do you lose debugging individual student environments?"
2. **Lab 00 — Building Your Vessel**
   * **Mission**: Each student creates an Ubuntu VM, installs Ubuntu, then runs `setup-client.sh` — one script that installs Fish, Starship, Docker, `git`, `kubectl`, `k9s`, and `aichat`, and wires up `/etc/hosts`.
   * **🧑‍🏫 Instructor Superpower (The Standardized Deck)**: Focus on the "coolness" and utility of Fish/Starship — but the deeper point is reproducibility. Providing one bootstrap script ensures every student starts with the exact same, highly-capable environment, eliminating OS discrepancies. You debug the *script* once, not thirty laptops forever.
   * **Gate**: Every student finishes the morning by running `verify-client.sh`. Nobody moves on with a failing check.

## 🌇 Afternoon: Rafts & Open Water
The fleet is built. Now the crew learns the raw elements of the new world — containers — and then paddles out into the ocean of Kubernetes.

### Key Objectives
- Understand the difference between a raw Container and a Kubernetes Pod.
- Build, tag, and push a container image to the island's registry.
- Generate declarative manifests and learn manual Kubernetes diagnostics (logs, exec).

### Activities & Missions
1. **The First Raft (Lab 01)**
   * Brief lecture: Linux kernel vs. user space, and how containers share the host kernel.
   * **Mission**: Write a basic `Dockerfile` for a web server, inject a custom `index.html` "Ship's Flag," build it, and push it to the internal cluster registry (Harbor).
   * **🧑‍🏫 Instructor Superpower (Containerized Labs)**: Explain that if they containerize homework, they eliminate 90% of technical support requests from students.
   * **🤖 Curiosity Side-Quest — The Socratic Boatswain**: Mid-lab, students create an `AGENTS.md` file and configure the cluster's local LLM to act as a pedagogical TA that *refuses* to hand over copy-pasteable code. This is where the evolving AI persona used throughout the seminar is introduced.
   * **Game: The Mutiny Challenge (Prompt Injection)**: During the day's debrief, an exercise in red-teaming — who can trick the Boatswain into breaking character and spitting out a raw `Dockerfile` *without* editing their strict `AGENTS.md` rules? It shows faculty exactly how students will try to bypass AI guardrails.
2. **From Container to Pod**
   * Lecture: how Kubernetes wraps the container in a Pod, and why (shared namespaces, networking, sidecars).
   * **Game: Dry-Run Relay (Quiz App)**: The instructor demos `kubectl run` generator commands on the projector. Students then race through a rapid-fire multiple-choice quiz on the locally-hosted Quiz App, testing their ability to identify valid `--dry-run` syntax.
3. **Paddling Out & Diagnostics (Lab 02)**
   * **Mission**: Claim a `Namespace`, generate a `pod.yaml` with `kubectl run --dry-run=client -o yaml`, deploy it, then practice diagnostics with `kubectl exec` and `kubectl logs`.
   * **Instructor Demo (The Ghost Ship)**: You `kubectl exec` into a running pod and edit its `index.html` live. Then you delete the pod — when it recreates, the manual edits are gone! This visually proves Container Immutability: if the configuration isn't baked into the `Dockerfile` at build time, it will sink.
   * **Game: Cluster Scavenger Hunt (Reconnaissance)**: The instructor hides a single Pod named `treasure-chest` in a randomly generated remote namespace. That pod continuously echoes a secret alphanumeric code in its logs. The first student to use global searches (`kubectl get pods -A`), locate the hidden pod, and read its logs to extract the code calls it out for the room!
