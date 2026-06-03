# Day 3: Automated Blueprints & Shipping Lanes

**Date**: June 3, 2026
**Theme**: Transitioning from manual steering to mass production and automated shipping with Hazel (Helm), GitOps (ArgoCD), and in-cluster CI (Gitea Actions).

## 🌅 Morning: The Finished Vessel, then Meet Hazel

Day 3 opens by **finishing what Day 2 started**. The instructor walks the complete 3-tier app end to end — the build no alliance quite finished yesterday — so the room sees the whole machine working before they templatize it. Then Hazel (Helm) takes the floor to turn that hand-built stack into a reusable blueprint.

### Key Objectives

- See the complete 3-tier app working end to end: **3 namespaces, 3 services, 3 deployments, and a single Gateway API** serving the app live on `wagbiz.org`.
- Understand *how the tiers connect* — frontend → backend → cache, routed through one Gateway — so the Helm chart they build next has a concrete target.
- Understand the value of templating with Helm.
- Package existing manifests into a reusable format.
- Replace manual `kubectl apply` with Helm deployments.


### Activities & Missions

1. **The Finished Vessel (30-min opening demo)**
   - Instructor-led walkthrough, no student keyboards. Show the completed 3-tier app as one connected system: the **three namespaces**, the **three Deployments** (frontend, backend, cache), the **three Services** wiring them together, and the **single Gateway API** that exposes the whole thing at `wagbiz.org`.
   - Trace a request out loud: browser → Gateway → frontend Service → backend Service → cache. Open the live URL so they see it actually serving.
   - **The point:** this is the exact stack they will templatize in Lab 01. *"You hand-built these pieces yesterday. This morning you see them connected. After the break, you stamp the whole thing from one blueprint."* — same app, one level up.
   - *(The in-cluster CI story — Gitea Actions, `git push → image in Harbor` — is no longer the opener. Mention it in one line if asked; it lives on as the Lab 02 stretch goal.)*
2. **The Problem with Raw YAML** (Hazel takes the floor, 60 min)
   - (Optional Reference: Helm Overview slides.)
   - Open with the callback to Tuesday's Kustomize demo: *operator vs. publisher, different jobs.*
   - Discuss how difficult it is to duplicate an application structure for different environments (e.g., Staging vs. Production) using only standard YAML.
2. **Drafting the Blueprint (Mission)**
   - Take the 3-Tier application components built on Day 2 and templatize them so that _each_ individual student can deploy the _entire_ stack independently into their own namespace.
   - Parameterize key values (like replica counts and image tags) into a `values.yaml` file to prove reusability.
   - **Game**: _Templating Speed Run_. Who can upgrade their Helm release with a new variable the fastest?
   - **🧑‍🏫 Instructor Superpower (The Master Blueprint)**: Emphasize that Helm is the ultimate tool for **scale**. Instead of recreating 30 distinct databases for 30 students, write *one* Helm chart. By simply changing the `student-name` in the `values.yaml`, instructors can spin up 30 identical, isolated lab environments instantly.

## 🌇 Afternoon: Automated Shipping Lanes (GitOps)

No more manual deployments to the cluster. We are turning our Helm blueprints over to the Automated Shipyards.

### Key Objectives

- Shift manual operations securely into GitOps declarations.
- Utilize CI loops for artifact creation.
- Command your own ArgoCD instance for CD synchronization.

### Activities & Missions

1. **The CI Loop (Gitea & Harbor)**
   - (Optional Reference: CI/CD slides).
   - Moving away from manual `docker push`, we rely on automated pipelines. Because we are in a secure/closed K3s VM environment, we will use **Gitea** (a locally hosted Git platform installed on our cluster).
   - **Mission**: Write a simple Git webhook / pipeline script in your Gitea repository so that pushing code automatically builds your custom Docker image and pushes it securely to the cluster's internal registry (Harbor).
2. **The CD Engine (ArgoCD)**
   - **Group Activity**: **Stand up your own Infrastructure!** Every student receives and configures their own isolated ArgoCD instance to orchestrate their namespace.
   - Stop using `helm install` manually! Commit your Helm chart to your local Gitea repository, and wire your ArgoCD application to listen to that Gitea instance.
   - Watch changes automatically sync whenever you push to Gitea.
   - **🧑‍🏫 Instructor Superpower (Self-Healing Infrastructure)**: With Self-Heal on, broad rights are *safe*. Have students raid a crewmate's fleet — `kubectl delete` a neighbor's deployment — and watch ArgoCD rebuild it from the Captain's Log within seconds. The "Aha!" Moment: the only durable way to change a fleet is a **pull request** someone merges. `kubectl` is a suggestion; **Git is the law.**

## 🪢 Late Afternoon Callback: Close the Loop

After the ArgoCD lab, run a 2-minute callback: *"Edit your chart, push to Gitea, and watch."* ArgoCD syncs, the new version rolls out, and the live URL shows the change — no `kubectl apply`, no `helm upgrade` by hand. That's the moment students see the full `git push → live app` story land in their own cluster.

## 🧭 Late Afternoon Lecture: The Quartermaster's Manifest

The labs are done. Now lift their eyes to the horizon — a ~30-minute closing lecture that does two things: shows the room **everything they could teach** on a platform like this, and gives them the name for what they've been building all week — **platform engineering**.

- (Reference: slides at [`slides/day-03/the-quartermasters-manifest.md`](../slides/day-03-the-quartermasters-manifest.html).)

### Part I — The Hold (the menu, ~10 min)

- Kubernetes is mis-filed as "DevOps." It is really a **lab-delivery platform** for *any* subject.
- Walk the shelf by discipline so every instructor sees their own course on it: **Python/data science** (JupyterHub, Binder, Spark/Ray), **AI/ML** (Ollama, Kubeflow, KServe, GPU sharing), **web/JS** (code-server, preview envs), **systems/C/C++** (toolchain containers, KubeVirt VMs), **networking** (Clabernetes, Cilium, service mesh), **DevOps/SRE** (ArgoCD, Prometheus, Chaos Mesh), **databases & security** (CloudNativePG, Falco, Kyverno, Vault).
- **This is where Clabernetes now lives** — *one item on a long shelf*, named as the EVE-NG/GNS3 replacement for the networking faculty, not run as a hands-on lab. Same for vCluster and KubeVirt, which get the deep-dive treatment tomorrow morning.
- The five subject-independent superpowers: one URL = identical env, push-to-Git distributes a lab, isolated & disposable, self-hosted & private, the system state *is* the grade.

### Part II — The Idea Underneath: Platform Engineering (~20 min)

- **The reveal:** an instructor running 30 reproducible environments *is* a platform team. Students are the "developers"; the lab is the **Internal Developer Platform (IDP)**.
- The arc — sysadmin → DevOps → platform engineering — and why it maps to teaching: *"set up your own environment"* is the cognitive overload; **the lab is the paved road.**
- The vocabulary to send them home with: **IDP**, **golden path / paved road** (Spotify / Netflix), **platform-as-a-product**, **reduce cognitive load** (Team Topologies), and the **CNCF maturity ladder** (Provisional → Operational → Scalable → Optimizing — most college labs sit at Level 1; Level 2 is a solo-achievable leap).
- **Actionable close:** the four-question pocket test (self-service? golden path? fast reset? distribution?) and the Monday-morning first step — *don't build Backstage; containerize one painful environment and deliver it over a URL.*
- **🧑‍🏫 Instructor Superpower (You Are the Platform Team)**: framed as agency — the environments an educator can choose to support have radically expanded, and they now have both the tools and the vocabulary to build them on purpose.

> Tees up Day 4: tomorrow morning the menu narrows to three deep dives — vCluster, KubeVirt, Chaos — then the Pirate strikes.

## 🏁 Closing the Day: The Flash Poll

End the day with the Quizler flash poll (`poll.{{ lab_domain }}`, `quiz-content.quizler`) — the Helm + GitOps/ArgoCD round. Because the room has now *done* the Helm lab and the ArgoCD self-heal lab, every question is earned. Run it as the day's closing beat. *(Logistics for any end-of-day recognition are the instructor's to run, off-script.)*

---

### 🤖 Curiosity Side-Quest: The Shipyard & The Logbook
_Evolving the Socratic Boatswain `AGENTS.md` context for automation._

- **Mission**: GitOps relies entirely on a mental model: "Git is Truth." Let's force the AI to ensure students understand this before it helps them.
- Append `Rule Update 3` to `~/lab/AGENTS.md`, then `.exit` and re-run `hail` so the new rule loads:
  > *"1. If I ask about Helm Go-Template syntax (like `{{ range }}`), DO NOT write the loop. Refer to loops as the 'Ship's Ledger' and ask me what list from my `values.yaml` I am iterating over first. 2. If I complain that my ArgoCD application is 'OutOfSync' or 'Degraded', refuse to help! Demand that I explain to you the difference between the 'Captain's Log' (Desired State perfectly stored in Git) and the 'Crew's Actions' (Live State in the cluster). Only after I explain the difference can you give an Argo UI hint."*
- Try manually deleting a Pod using `kubectl` against your ArgoCD deployment and ask the AI why it came back!
