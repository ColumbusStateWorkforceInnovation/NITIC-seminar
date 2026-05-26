# Instructor Guide: Day 1 (The Ship Has Sunk)

This guide provides the minute-by-minute cues for you to run the classroom effectively.

!!! note "Before 9:00 AM"
    Run the [Setup Troubleshooting → Pre-Flight Checklist](setup-troubleshooting.md#pre-flight-checklist-before-june-1) a week out — chiefly: stage the Ubuntu ISO locally so the class isn't downloading 6 GB at once, and test that a classroom desktop runs a 64-bit VM. Write `SERVER_IP` on the board.

## 09:00 - 09:15 | Welcome & Storytime
**Goal:** Settle the class and frame the day.
- **Action (Storytime):** Project the PDF and read the "Day 1 Morning" passage from `book-readings.md`.
- **Action:** Distribute the printed `one-pager.md`.
- **Talking Point:** Set expectations — "The whole morning is building your ship. It feels slow, but by lunch every one of you is on an identical, fully-loaded Linux environment. That is the instructor superpower we're modeling: you debug the *setup script* once, not thirty laptops forever."
- **Action:** Write `SERVER_IP` on the board (the lab domain is built into the setup script); point the class at where the Ubuntu ISO is staged.

## 09:15 - 12:00 | Lab 00: Building Your Vessel (Setup)
**Goal:** Every student ends with a working Ubuntu VM that passes `verify-client.sh`.
- **Action:** Have students open `lab-00-building-your-vessel.md` and run it **as a class** — demo each Part on the projector, then let the room catch up before moving on. Do not let fast students sprint ahead; pace to the middle of the room.
- **Pt 1 (≈09:15–10:30):** Launch VirtualBox (pre-installed on the desktops), create the VM, start the Ubuntu installer. The installer itself runs 10–20 min — kick it off *before* the 10:30 break so it installs while everyone is out.
- **Break 10:30–10:45:** Ubuntu finishes installing unattended.
- **Pt 2 (≈10:45–12:00):** First boot, `git clone`, `setup-client.sh`, then `verify-client.sh`. The bootstrap script runs 5–15 min mostly unattended — use that window to circulate and clear stragglers.
- **Watch for:** the `docker` group needs a fresh login — remind everyone to **log out and back in** after `setup-client.sh`. Keep the [Troubleshooting sheet](setup-troubleshooting.md) handy for the odd machine that misbehaves.
- **Gate:** nobody goes to lunch with a failing `verify-client.sh`. A broken hull now is a lost afternoon later.

## 12:00 - 01:00 | Lunch

## 01:00 - 01:45 | The Wreckage (Lecture)
**Goal:** Explain what they just built.
- **Lecture:** Linux Kernel vs. User Space, and how Containers share the host Kernel. Tie it back to the VM they just installed — "you now have a Linux kernel; containers are just isolated user space on top of it."
- **Talking Point:** Reinforce the Standardized Deck superpower — one bootstrap script gave the whole room the same Fish shell, Starship prompt, and tool versions, eliminating OS support tickets.

## 01:45 - 03:00 | Lab 01: The First Raft
**Goal:** Students build and push their first Docker image.
- **Action:** Instruct students to open `lab-01-the-first-raft.md` on the MkDocs site (`docs.{{ lab_domain }}`).
- **Action (The Trap):** Let them struggle to figure out the `Dockerfile` syntax. Monitor the room.
- **Action (The Save):** Interrupt and introduce the Socratic Boatswain (`aichat`). Have them create `AGENTS.md` and paste the Boatswain rules from the lab doc. *(This is where the AI persona is introduced — there is no longer a standalone AI Connect block.)*
- **Talking Point:** "This is how you govern AI in your classroom. Don't ban it; shape it. The Boatswain refuses to give them the answer, but it acts as a 24/7 TA."
- **Gamification:** Keep an eye on your Harbor dashboard (`harbor.{{ lab_domain }}`). Call out the first student image that pops up into the `raft-fleet` project!

## 03:00 - 03:15 | Break

## 03:15 - 04:00 | Into the Deep (Lecture)
**Goal:** Transition from pure Docker to Kubernetes Pods.
- **Lecture:** Explain the "Pod" abstraction. Why do we need a pod? (Shared namespaces, networking, sidecars).
- **Action (Flash Poll):** Open the Quiz App (`poll.{{ lab_domain }}`). Load the 5 questions from `quiz-content.quizler`. Have the students race to answer them. Use the results to gauge comprehension before the afternoon lab.

## 04:00 - 05:00 | Lab 02: Paddling Out & Debrief
**Goal:** Imperative generation (`--dry-run`), diagnostics (`logs`, `exec`), and close out the day.
- **Action (Cluster onboarding — do this first):** Lab 02 is the first time students need live cluster access. Each student needs a **Rancher** login ready — have those accounts set up — then the lab's opening section walks them through copying their kubeconfig from the Rancher UI into `~/.kube/config`. Until they're in Rancher, `kubectl` has nothing to talk to.
- **Action:** Have them follow `lab-02-paddling-out.md`.
- **Action (The Ghost Ship Demo):** Early in the lab, stop the class and project your terminal. Exec into a running Nginx pod, change the `index.html` manually, show it working — then delete the pod and show the edits are gone when it respawns. *This visual permanently cements infrastructure immutability.*
- **Action (Scavenger Hunt):** Around 4:25 PM, secretly run `./scripts/day-01-scavenger-hunt.sh` from your terminal. Announce a Treasure Chest has been hidden; first student to find it and read the logs calls out the code.
- **Debrief (last ~10 min):** Ask the faculty how they feel about the Socratic Boatswain — did it help or hinder? Optionally run the **Mutiny Challenge** (prompt injection): who can trick the Boatswain into emitting a raw code block *without* editing `AGENTS.md`? Close by projecting the PDF and reading the "Day 1 Afternoon" passage from `book-readings.md`.

---

!!! note "What changed from the original Day 1"
    The morning is now a dedicated live VM build (Lab 00). To make room, the two lectures were tightened (90 → 45 min each) and the standalone end-of-day **AI Connect** block was removed — the Socratic Boatswain is introduced inside Lab 01, and the Mutiny game + afternoon storytime fold into the Lab 02 debrief. If a block runs long, protect the labs and trim lecture.
