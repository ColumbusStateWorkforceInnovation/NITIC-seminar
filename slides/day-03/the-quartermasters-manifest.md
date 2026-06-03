---
marp: true
auto-scaling: false
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 3 · The Quartermaster's Manifest"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 3 · Closing Lecture · ~30 minutes

# The Quartermaster's Manifest

## Everything this island can teach — and the idea that makes it possible

*A manifest is the ship's cargo list. It is also a Kubernetes file. Today, both meanings at once.*

<!-- This is the wind-down lecture after the Helm and ArgoCD labs. Two jobs: (1) show them the full hold — every kind of class that can run on the platform they just used, so each instructor sees their own subject on the shelf; (2) give them the word for what they have been doing all week — platform engineering — and arm them to go further. Keep Act I brisk (a market stall, not a deep dive). Spend the real minutes on Act II. No hands-on here; this is "lift your eyes to the horizon." -->

---

## Two questions before we close

You spent today **building**: a Helm chart, a GitOps pipeline, an ArgoCD that heals itself.

Step back and ask:

1. **What can you actually *teach* on a platform like this?** — far more than DevOps. (Part I)
2. **What is this thing you've been building all week even called?** — it has a name, a literature, and a career path. (Part II)

> The tools were the vehicle. These two answers are the souvenir you take home.

<!-- Frame the lecture as the payoff for the whole week. They came to learn Kubernetes; they are leaving with a transferable discipline. Name the two parts so they can track position. -->

---

<!-- _class: chapter -->

#### Part I

# The Hold

```text
        _____________________
       /  ||  ||  ||  ||  ||  \
      /___||__||__||__||__||___\
      |   the ship's manifest   |
      |  what's in the cargo?   |
       \_______________________/
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

> *"Open the hold. Let them see everything we're carrying."*

---

## One cluster. Every subject.

- Kubernetes is filed under "DevOps." That is a **category error.**
- What you really have is a **lab-delivery platform**: a way to hand any student an identical, isolated, disposable environment over a URL.
- The subject inside that environment can be *anything* — Python, AI, networking, C, databases, security.
- Everything on the next few slides runs on the **same island you already stood up** — no new infrastructure, no IT ticket.

*Find your subject on the shelf. The point is: it's already there.*

<!-- This is the thesis of Part I. Say it plainly: the room thinks Kubernetes is for the networking/DevOps faculty. It is actually the substrate under all of their courses. Tell them to listen for their own discipline in the next slides. -->

---

## Python · Data Science · Analytics

| Platform | What it lets you teach |
| :--- | :--- |
| **JupyterHub** (Zero-to-JupyterHub) | A private notebook server *per student*, spawned on demand. The classroom standard at Berkeley & Brown. |
| **Binder** / BinderHub | Turn any Git repo into a live notebook over a URL — zero install. |
| **Spark / Dask / Ray** on K8s | Distributed data processing; "big data" without a data center. |
| **Airflow** | Data-engineering pipelines and DAG orchestration. |

> The same GitOps loop you ran in Lab 02 is how a JupyterHub gets delivered: one chart in Git, every student's notebook server in sync.

<!-- This is the slot for the data-science and analytics faculty. JupyterHub is the killer app — the per-student-environment-over-a-URL story, built on the exact GitOps loop they ran in Lab 02. If anyone teaches stats/Python/R, this is their slide. -->

---

## AI · Machine Learning · LLMs

| Platform | What it lets you teach |
| :--- | :--- |
| **Ollama + Open WebUI** | Self-hosted LLMs, entirely in the room — the Boatswain you've used all week. Prompt engineering, RAG, local inference. |
| **Kubeflow** | End-to-end MLOps: notebooks, training pipelines, model registry. |
| **KServe / Seldon** | Model *serving* — deploy a model as a live API and teach inference at scale. |
| **vLLM** + GPU scheduling | High-throughput LLM inference; share one GPU across many students (time-slicing / MIG). |

> The AI never has to leave the building — no per-seat API bill, no data egress.

<!-- The AI faculty's slide. The hook for a college: you can teach modern AI without sending student data to a vendor and without a per-token bill. GPU sharing is the practical unlock — one card, a whole class. (If they ask: yes, GPU quota and drivers are the real-world friction — name it honestly.) -->

---

## Web · JavaScript · npm · Full-Stack

| Platform | What it lets you teach |
| :--- | :--- |
| **code-server** (VS Code in a browser) | A full IDE per student over a URL — no laptop setup, identical for all 30. |
| **The 3-tier app** you built today | Frontend / backend / database, real services, real routing. |
| **Preview environments** (vCluster + ArgoCD) | A live, isolated deploy per pull request — teach real review workflows. |
| **Gitea Actions / Tekton** | npm build + test pipelines that run in-cluster. |

> "Works on my machine" dies here: *the machine is the cluster, and everyone has the same one.*

<!-- The web-dev faculty's slide. code-server is the headline: it solves the single biggest time sink in any coding class — getting 30 laptops into an identical, working state. -->

---

## Systems · C / C++ · Operating Systems

| Platform | What it lets you teach |
| :--- | :--- |
| **code-server + toolchain image** | A pinned compiler/build environment, identical for everyone — no "which gcc?" |
| **Reproducible build containers** | The exact same libc, headers, and flags for every student, every term. |
| **KubeVirt** | *Full virtual machines* as cluster objects — kernel work, drivers, OS internals, root access, safely. |
| **Argo / Tekton pipelines** | CI for compiled languages: build matrices, unit tests, artifacts. |

> When a student melts their VM: delete it, redeploy, back in a minute.

<!-- The C/C++ and OS faculty's slide. The insight: a container pins the toolchain (huge for reproducibility), and KubeVirt covers the cases where you genuinely need a whole machine — kernel modules, OS courses. This is where Day 4's KubeVirt demo pays a dividend. -->

---

## Networking

| Platform | What it lets you teach |
| :--- | :--- |
| **Clabernetes / Containerlab** | Virtual **commercial router** topologies — Nokia SR Linux, Arista, Cisco. BGP, OSPF, EVPN. Replaces GNS3 / EVE-NG. |
| **Cilium + Hubble** | eBPF networking, NetworkPolicy, live traffic flow maps. |
| **Istio / Linkerd** | Service mesh: traffic shaping, mTLS, retries, canaries. |
| **KubeVirt** | Windows Server, Active Directory, DHCP/DNS — on the *same* fabric as the containers. |

> *Clabernetes is one item on this shelf* — the heavy-hardware-replacement that used to need a rack of gear.

<!-- The networking faculty's slide — and the home for Clabernetes now that it's a mention, not a lab. The pitch: a multi-router lab for every student from a few lines of YAML, no EVE-NG license, no physical lab. -->

---

## DevOps · SRE · Cloud-Native

| Platform | What it lets you teach |
| :--- | :--- |
| **ArgoCD / Flux** | GitOps — what you did today. |
| **Helm / Kustomize** | Templating and configuration — also today. |
| **Prometheus / Grafana / Loki** | Metrics, dashboards, logs — observability from scratch. |
| **Chaos Mesh / LitmusChaos** | Resilience and failure testing — *tomorrow's pirate.* |
| **Harbor + Trivy + cosign** | Registry, image scanning, signing — software supply-chain security. |

> This is the "home" discipline — but notice it's only **one column** of the manifest.

<!-- The DevOps faculty's slide. For them this is review; the point for everyone else is that "the cloud-native stack" is a teachable curriculum in itself, and most of it is already running on the island. -->

---

## Databases · Security · and the rest

| Platform | What it lets you teach |
| :--- | :--- |
| **CloudNativePG** & DB operators | Real high-availability Postgres / MySQL / Mongo — actual DBA skills, with failover. |
| **MinIO** | S3-compatible object storage — cloud storage patterns, locally. |
| **Falco** + **Kyverno / OPA** | Runtime threat detection and policy-as-code — defensive security. |
| **Vault** | Secrets management done properly. |
| **KubeVirt** sandboxes | Isolated VMs for malware analysis, CTFs, red-team labs. |

<!-- Catch-all slide so the database and cybersecurity faculty see themselves too. The DBA angle is underappreciated: operators give students a *real* HA database to break and recover, not a toy. -->

---

## The five superpowers (why *any* subject wins)

Whatever you teach, the platform gives you the same five things:

1. **One URL, identical environment** — 30 students, zero local setup, no "works on mine."
2. **Push to Git → everyone updates** — distribute a lab change to the whole class instantly.
3. **Isolated & disposable** — break it freely, reset in a minute.
4. **Self-hosted & private** — air-gapped if you want; no per-seat SaaS, data stays in the room.
5. **The system state *is* the grade** — auto-gradeable labs (you'll see this tomorrow).

> These are subject-independent. That is the whole point.

<!-- This is the synthesis slide for Part I. If a slide on their specific subject didn't land, this one should: the *delivery* superpowers apply no matter what they teach. Land #2 especially — GitOps-as-lab-distribution is the single most novel idea for an educator. -->

---

<!-- _class: chapter -->

#### Part II

# The Idea Underneath

```text
        .-""""""-.
      .'          '.
     /   O      O   \
    :                :
    |                |    what do we call
    :    \      /    :    this thing you built?
     \    '----'    /
      '.          .'
        '-......-'
```

> *"You've been speaking prose your whole life without knowing it."*

---

## You've been a platform engineer all week

- A platform team builds a **self-service environment** so *developers* can do their job without becoming infrastructure experts.
- Swap two words:

| Industry | Your classroom |
| :--- | :--- |
| Platform team | **You** |
| Developers | **Your students** |
| Internal Developer Platform | **The lab** |
| "Ship features, don't fight infra" | "Learn the subject, don't fight setup" |

- The problem is *identical*: many people need a working environment; none of them should have to build it from scratch.

<!-- The reveal, and the spine of Part II. Don't rush it. The room has been treating this week as "learning Kubernetes." Reframe it: they were doing platform engineering — they just didn't have the word. Once that clicks, every following slide is them learning the vocabulary for something they already understand intuitively. -->

---

## How we got here

```text
   sysadmin  ──▶   DevOps   ──▶   platform engineering
   (I run it)    (you run it)    (here's a paved road
                                  so you don't have to)
```

- **DevOps** said: developers should own their infrastructure. Good in spirit — but it dumped a *mountain* of cognitive load on people who just wanted to ship.
- **Platform engineering** is the correction: give people a **supported, opinionated path** so they get self-service *without* having to learn everything underneath.
- You live this every term. *"Set up your own environment"* is the DevOps-era overload. **The lab is the paved road.**

<!-- The historical arc, fast. The punchline is the last bullet: the thing they already know is painful — telling students to set up their own environment — is the exact failure mode platform engineering exists to fix. This makes the abstract concrete for them. -->

---

## The vocabulary: IDP

#### Internal Developer Platform

- The **self-service layer** that sits between a person and the messy infrastructure.
- A developer (student) asks for *what they want* — a notebook, a database, a cluster — and gets it, without filing a ticket or reading a wiki.
- It **abstracts the complexity away.** They don't see Helm, ArgoCD, namespaces — they see "my environment is ready."

> In your class, the IDP is the lab. Today you built a working one.

<!-- Term #1. Keep the definition crisp. The key word is self-service: the test of an IDP is whether the user gets what they need without the platform team in the loop. -->

---

## The vocabulary: the Golden Path

- The **one supported, opinionated, well-lit route** through a common task.
- Spotify named it the **"Golden Path."** Netflix calls it the **"Paved Road."**
- Not a cage — the *easy* path. Anything-goes overwhelms; forced-standardization rebels. The golden path is the sweet spot in between.
- **You already build these:** a starter repo, a setup script, "here's the one way we do it in this course." Now you have the name.

> A golden path is how *one* of you supports *thirty* of them without burning out.

<!-- Term #2 — and the most useful one for them. Every good instructor already makes golden paths; naming it lets them do it deliberately. The Spotify/Netflix lineage gives it credibility with their IT departments. (Nautical bonus, if you want it: Spotify took the name from the "Golden Path" in Dune — a single safe route through danger.) -->

---

## The mindset: platform as a *product*

- A platform has **users**, and users **vote with their feet.**
- If your lab is painful, students route around it — work on their laptops, fall behind, drop the tool.
- So you design for **adoption, not mandate**: make the supported path the *easiest* path.
- Start with the **thinnest viable platform** — the smallest thing that actually helps — and grow it from feedback.

> The same instinct that makes a good course makes a good platform: *meet the user where they are.*

<!-- Term #3. This is the cultural heart of platform engineering and it maps perfectly to teaching: you cannot force adoption, you earn it. The "thinnest viable platform" idea is also the antidote to over-engineering, which sets up the Monday-morning advice later. -->

---

## The goal: reduce cognitive load

- Every learner has a **fixed budget** of working memory.
- Spend it on *the subject* — BGP, recursion, gradient descent — not on *kubeconfig and pip*.
- A platform's job is to **absorb the incidental complexity** so the scarce attention goes to the actual learning.
- This is the *Team Topologies* insight, and it is just good pedagogy with an engineering name.

> Yesterday's worry — "abstraction stacking" — is cognitive load. The platform is how you pay it down.

<!-- Term #4, and the bridge back to pedagogy. This is the slide that tells the educators platform engineering isn't a detour from teaching — it IS teaching, applied to the environment. Connect it to the cognitive-load conversation that's been running all week. -->

---

## Where any lab sits: the maturity ladder

The CNCF Platform Engineering Maturity Model, read as an educator:

| Level | In industry | In your classroom |
| :--- | :--- | :--- |
| **1 · Provisional** | ad-hoc, manual | "Set it up on your laptop." Snowflakes, *works-on-mine.* |
| **2 · Operational** | a shared platform exists | One JupyterHub / code-server everyone uses. |
| **3 · Scalable** | self-service & repeatable | GitOps-distributed labs, per-student isolation, rebuildable from a repo. |
| **4 · Optimizing** | a product, measured | A self-service catalog; students provision their own; you measure & iterate. |

> Most college labs live at **Level 1.** Getting to **Level 2** is a giant leap — and you can do it *alone.*

<!-- Term #5 — a real, citable framework (CNCF Platforms Working Group, 2023). Don't drown them in the five aspects; the four levels are enough. The takeaway is the last line: name where they are (Level 1) and where one motivated instructor can realistically get to (Level 2). That's an achievable, non-intimidating goal. -->

---

## The pocket test: four questions

Hold any lab you run up to these four questions:

1. **Self-service** — can a student get a working environment *without me?*
2. **Golden path** — is there *one obvious, supported* way to do it?
3. **Reset** — if they break it, can they get back to clean *fast?*
4. **Distribution** — when I improve the lab, does *everyone* get the update?

> Four "no"s is Level 1. Four "yes"es is the platform you used today.

<!-- This is the single most actionable slide — tell them to screenshot it. It turns the whole abstract discipline into a four-item checklist they can apply to next semester's syllabus on the drive home. -->

---

## What to do Monday morning

- **Don't build Backstage.** Don't boil the ocean.
- Pick **one** painful environment in **one** class — the one where setup eats the first week.
- **Containerize it once. Deliver it over a URL** (code-server or JupyterHub).
- That's a golden path. That's Level 2. That's the whole game, started.

> The smallest paved road beats the grandest plan that never ships.

<!-- The "do this first" slide. The most common failure mode is over-ambition; counter it directly. One container, one URL, one class — a concrete, finishable first step. This is the action that turns the lecture into behavior. -->

---

## The tools to go look up

Named, not taught — your map for after the seminar:

| Tool | What it does | When you'd reach for it |
| :--- | :--- | :--- |
| **Backstage** (CNCF) | Developer portal / catalog | A "front door" for your courses & labs |
| **Crossplane** (CNCF) | Provision infra via the K8s API | Students request environments declaratively |
| **ArgoCD** | GitOps delivery | Push a change → everyone gets it (you did this today) |
| **vCluster** | A real cluster per user | Self-service, isolated clusters (tomorrow's demo) |
| **Port / Humanitec** | Commercial IDPs | If you'd rather buy the portal than build it |

<!-- A leave-behind reference. You are not teaching these — you are giving them search terms so the curious ones have somewhere to go. Note which they've already touched (ArgoCD) and which is coming (vCluster) to anchor the unfamiliar names to familiar ones. -->

---

## Read these on the flight home

- **CNCF Platform Engineering Maturity Model** — the framework on the ladder slide. `tag-app-delivery.cncf.io`
- **CNCF Platforms Working Group** — the community defining this field. `platforms.cncf.io`
- **Team Topologies** (Skelton & Pais) — the book behind "reduce cognitive load."
- **internaldeveloperplatform.org** — vendor-neutral IDP reference.
- **platformengineering.org** — community, blog, the golden-path writing.

<!-- Resource slide. All real, all current. Team Topologies is the one book to name if you name only one. Keep this up while you transition to the closer. -->

---

## Instructor Superpower

#### You are the platform team for your students

- All week you learned the platform. **Platform engineering is the discipline of building it on purpose.**
- Every hour you spend paving a road is an hour *thirty* students don't spend lost in setup.
- You don't wait for IT to offer a capability — you have just seen that you can **build the environment yourself**, for a lesson, a course, or a whole program.
- The job was never "teach Kubernetes." The job is **clearing the path to the thing you actually teach.**

<!-- The destination slide. Agency, not grievance: the environments an educator can choose to support have radically expanded, and they now have both the tools and the vocabulary to build them deliberately. Land it slow. Then hand off to Day 4. -->

---

<!-- _class: lead -->
<!-- _footer: "" -->

# The hold is open.

```text
   ~~~^~~~~~^~~~~~~^~~~~^~~~~~^~~~
  ~~~~~~^~~~~~~^~~~~^~~~~~~^~~~~~~~
   ~^~~~~~^~~~~~~^~~~~~^~~~~~^~~~~~
```

*Tomorrow morning we take three items off this shelf — vCluster, KubeVirt, and Chaos — and go deep. Then the Pirate comes.*

<!-- Close Day 3 here. Tee up the Day 4 arsenal explicitly so the broad menu they just saw narrows to three deep dives in the morning. Send them out knowing the survey wasn't filler — it was the map, and tomorrow they walk part of it. -->
