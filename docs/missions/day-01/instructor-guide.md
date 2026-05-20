# Instructor Guide: Day 1 (The Ship Has Sunk)

This guide provides the minute-by-minute cues for you to run the classroom effectively.

## 09:00 - 10:30 | The Wreckage (Lecture)
**Goal:** Settle the class and bypass the "It doesn't work on my Windows laptop" phase.
- **Action (Storytime):** Project the PDF and read the "Day 1 Morning" passage from `book-readings.md`.
- **Action:** Distribute the printed `one-pager.md`.
- **Action:** Have all students run `setup-client.sh`.
- **Talking Point:** Emphasize the *Instructor Superpower* here. "By providing one bootstrap script, you ensure every student has the exact same terminal (Fish), the exact same prompt (Starship), and the exact same tool versions. You are no longer providing Windows/Mac tech support."
- **Lecture:** Brief introduction to Linux Kernel vs User Space, and how Containers share the Kernel.

## 10:45 - 12:00 | Lab 01: The First Raft
**Goal:** Students build and push their first Docker image.
- **Action:** Instruct students to open `lab-01-the-first-raft.md` on the MkDocs site (`docs.{{ lab_domain }}`).
- **Action (The Trap):** Let them struggle to figure out the `Dockerfile` syntax. Monitor the room.
- **Action (The Save):** Interrupt and introduce the Socratic Boatswain (`aichat`). Have them paste the `AGENTS.md` context. 
- **Talking Point:** "This is how you govern AI in your classroom. Don't ban it; shape it. The Boatswain refuses to give them the answer, but it acts as a 24/7 TA."
- **Gamification:** Keep an eye on your Harbor dashboard (`harbor.{{ lab_domain }}`). The first student image that pops up into the `raft-fleet` project gets a book copy!

## 01:00 - 02:30 | Into the Deep (Lecture)
**Goal:** Transition from pure Docker to Kubernetes Pods.
- **Lecture:** Explain the "Pod" abstraction. Why do we need a pod? (Shared namespaces, networking, sidecars).
- **Action (Flash Poll):** Open the Quiz App (`poll.{{ lab_domain }}`). Load the 5 questions from `quiz-content.md`. Have the students race to answer them. Use the results to gauge comprehension before moving to the afternoon lab.

## 02:45 - 04:15 | Lab 02: Paddling Out
**Goal:** Imperative generation (`--dry-run`) and Diagnostics (`logs`, `exec`).
- **Action:** Have them follow `lab-02-paddling-out.md`.
- **Action (The Ghost Ship Demo):** Before they get too far, stop the class. Project your terminal. Exec into a running Nginx pod. Change the `index.html` manually. Show it working. Then, delete the pod. Show the class that the edits are completely gone when it respawns. *This visual permanently cements the concept of infrastructure immutability.*
- **Action (Scavenger Hunt):** At 3:30 PM, secretly run `./scripts/day-01-scavenger-hunt.sh` from your terminal. Announce that a Treasure Chest has been hidden. The first student to find it and read the logs gets the final prize of the day.

## 04:15 - 05:00 | AI Connect & Debrief
- **Discussion:** Ask the faculty how they feel about the Socratic Boatswain. Did it help? Did it hinder?
- **Game (Prompt Injection):** Challenge the room to trick the Boatswain into giving them a raw code block *without* changing the `AGENTS.md` file. Explain that this is exactly what their students will do, and they need to be prepared for it.
- **Action (Storytime):** Project the PDF and read the "Day 1 Afternoon" passage from `book-readings.md` to close out the day.
