---
marp: true
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 1 · The Wreckage"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 1 · Lecture 1 · 45 minutes

# The Wreckage

## Linux Basics & the Birth of Containers

*The mainframe is gone. Time to learn what we're standing on.*

<!-- Welcome them back from the morning VM build. Energy check: they have been heads-down in a setup script for three hours. This lecture is the payoff — it explains what they just built. Keep it brisk; the labs are where the day lives. -->

---

## Where we are

- This morning you built a **ship**: one Ubuntu VM, one `setup-client.sh`, an identical environment for every sailor in the crew.
- The next 45 minutes: what that ship actually **is** — and the lighter craft we build on top of it.
- Four short legs:
  - Why the old ship sank
  - The anatomy of a Linux machine
  - How a container actually works
  - How we build one
- Then we hit the water: **Lab 01 — The First Raft**.

<!-- Frame this as the bridge between "I ran a script" and "I understand my environment." Promise them the lecture is short and the lab is long. -->

---

<!-- _class: chapter -->

#### Part I

# Why the SS Legacy Sank

```text
          |
         /|\
        / | \
       '--+--'
         )_)
        )___)
      __)_____)__
      \_________/
    ~~~~~~~~~~~~~~~
```

> *"A ship too proud to change course is just a reef with sails."* — the Boatswain

---

## The SS Legacy

> "His ship, the SS Legacy, was built around a mainframe which made it slow to change course."

- One enormous ship. One mainframe. Every function bolted to the same hull.
- This is a **monolith** — all the code and all its dependencies, shipped and run as a single unit.
- It floated for years... right up until it had to change.

<!-- Tie back to the morning storytime reading. The monolith is not "bad" — it is just rigid. Rigidity is the enemy on a changing ocean. -->

---

## What a monolith costs you

- **Change is risky** — edit one feature, rebuild and retest *everything*.
- **Failure spreads** — one leak floods the whole hull.
- **Scaling is blunt** — need more of one part? Launch another entire ship.
- **"Works on my machine"** — the environment is implicit and never written down.

*Faculty translation: thirty laptops, thirty slightly different ships — and an IT queue you don't control. One bootstrap script routes around both.*

<!-- Ask the room where they feel this. Not "how much time do you lose" — their week may be fine. The squeeze is structural: a lesson needs a working environment now, the IT department is understaffed and often a version or two behind, and the educator is caught in the middle between the two. That gap is the hook for the whole seminar. -->

---

## A new approach

> "They broke the work down into smaller problems, creating tiny, easily replaceable tools and building supplies."

- Stop trying to build one unsinkable ship.
- Build **many small craft** — each does one job, each replaceable without dragging the rest down.
- Those small craft have a name: **containers**.
- The rest of today is learning to build and sail them.

<!-- This is the thesis of the seminar in one slide. Small, replaceable, independent. -->

---

<!-- _class: chapter -->

#### Part II

# Anatomy of Your Vessel

```text
        .-'''-.
      .'  / \  '.
     /   /   \   \
    |---+-----+---|
     '-.._|_..-'
```

> *"Know every plank of your hull, or the sea will teach ye — the hard way."* — the Boatswain

---

## Every Linux system has two halves

```text
  +----------------------------------------------+
  |   USER SPACE      the deck - where you work   |
  |   fish . starship . docker . kubectl . aichat |
  +----------------------------------------------+
  |   THE KERNEL      the hull - Linux itself     |
  |   processes . memory . files . devices        |
  +----------------------------------------------+
  |   HARDWARE        CPU . RAM . disk . network  |
  +----------------------------------------------+
```

- The **kernel** runs the hardware. **User space** is every program you launch.
- Hold this two-layer picture — the whole container idea rides on it.

<!-- Draw the line with your hand on the projection: above it is "you", below it is "the machine". -->

---

## The Kernel — the hull

- The privileged core of the operating system. You stand on it; you never touch it directly.
- Its job:
  - talk to the **hardware**
  - **schedule** which program runs when
  - hand out **memory**
  - own the **filesystem**
  - enforce who is allowed to do what
- Exactly **one** kernel runs the machine. Everything on board shares it.

*Remember that last point — it is the entire reason containers are light.*

---

## User Space — the deck

- Everything above the kernel — every program the crew actually runs.
- Everything `setup-client.sh` installed this morning lives here: Fish, Starship, Docker, `kubectl`, `aichat`.
- Programs can't poke the hardware directly. They **ask the kernel**, through **system calls**.
- An app, plus the libraries and files it needs to run = a **user-space environment**.

<!-- "System call" is the only piece of jargon here. Analogy: the crew does not steer the rudder by hand; they call down an order to the kernel. -->

---

## Everything is a process

- A **process** is simply a running program.
- `setup-client.sh` was a process. The shell you are typing into is one right now.
- Each process has an **ID**, an **owner**, and its own slice of **memory**.
- The kernel decides who runs and when — see it yourself with `ps aux` or `top`.

> **Hold this thought:** a container is *just a process*. We will come straight back to it.

---

## Everything is a file

- In Linux, **almost everything is a file** — documents, directories, even devices and disks.
- It all hangs off a **single tree**, starting at the root: `/`.
- Every file carries **permissions** — who may read, write, or execute it.
- A container gets its **own private view** of this tree. That is the trick we are building toward.

<!-- Don't go deep on permissions — just plant that "own view of the filesystem" is coming. -->

---

## So — what did you build this morning?

```text
  +--------------------------------------+
  |  USER SPACE   fish, docker, kubectl  |
  +--------------------------------------+
  |  ONE LINUX KERNEL                    |
  +--------------------------------------+
  |  (virtual) HARDWARE   from VirtualBox|
  +--------------------------------------+
```

- Virtual hardware → **one** Linux kernel → a user space full of tools.
- Keep this on screen. Containers do **not** replace any of it.
- They **reuse the kernel** and add a fresh, isolated user space on top.

<!-- This is the pivot slide into containers. The VM they built is the reference picture for everything that follows. -->

---

<!-- _class: chapter -->

#### Part III

# From Hull to Crates

```text
     .-=-=-.
    | | | | |
    | | | | |
    | | | | |
     '-=-=-'
```

> *"Why haul a whole ship when a crate'll do? Pack light, sail fast."* — the Boatswain

---

## The real problem

- Shipping your app's **code** is easy. Shipping the **environment it needs** is the hard part.
- App A needs library version 1. App B needs version 2. Same ship — now they fight.
- *"Works on my machine"* really means: my environment differs from yours, and **neither is written down**.
- We need to package the app **together with its whole user space**.

<!-- This is dependency hell. Everyone in the room has lived it. Name it plainly. -->

---

## First instinct: give every app its own ship

```text
   +------+  +------+  +------+
   | App  |  | App  |  | App  |
   | Libs |  | Libs |  | Libs |
   | Guest|  | Guest|  | Guest|
   |  OS  |  |  OS  |  |  OS  |
   +------+  +------+  +------+
   +--------------------------+
   |        Hypervisor        |
   +--------------------------+
   |     Host OS  +  Kernel   |
   +--------------------------+
   |          Hardware        |
   +--------------------------+
```

- It works — full isolation. But every ship hauls a **whole Guest OS**:
- gigabytes of disk · minutes to boot · **its own kernel to patch**.

<!-- This is exactly what they did this morning, once. Imagine doing it thirty times per app. -->

---

## The insight: share the hull

```text
   +------+  +------+  +------+
   | App  |  | App  |  | App  |
   | Libs |  | Libs |  | Libs |
   +------+  +------+  +------+
   +--------------------------+
   |    Container Engine      |
   +--------------------------+
   |    ONE shared Kernel     |
   +--------------------------+
   |         Hardware         |
   +--------------------------+
```

- Does each app really need its own **kernel**? **No.**
- It needs its own **user space** — its own files and libraries.
- A **container** is an isolated user space running on the **host's** kernel.

---

## Isolation: Linux namespaces

- A container is just a process — so how is it walled off? With **namespaces**.
- Namespaces control what a process is allowed to **see**:
  - its own **process list**
  - its own **filesystem** tree
  - its own **network**
  - its own **hostname**
- Inside the crate, the program is convinced it is alone on the ship.

<!-- Namespace = what you can see. Say it that simply. -->

---

## Limits: Linux cgroups

- Namespaces decide what a process can **see**. **Control groups** (cgroups) decide what it can **use**.
- A ceiling on **CPU time**, **memory**, and **I/O** — enforced by the kernel.
- One greedy crate can't hog the whole deck and capsize its neighbours.
- Namespaces + cgroups are both **ordinary kernel features**. Nothing exotic — Linux already had them.

<!-- cgroups = what you can use. Pair it with the namespaces slide: see vs. use. -->

---

## So what *is* a container?

- A container is **not a tiny virtual machine**.
- It is: a normal **Linux process** + **namespaces** (what it sees) + **cgroups** (what it uses) + its own packaged **user space** — all riding the **shared host kernel**.
- No Guest OS. No boot sequence. It starts in **milliseconds**.

> **The Boatswain:** "A container's just a wooden crate, lad. The hull is the OS, the loading docks are the ports — the crate only carries the cargo."

<!-- The payoff slide of Part III. If they remember one slide, make it this one. -->

---

<!-- _class: chapter -->

#### Part IV

# Building a Crate

```text
          _
         (o)
          |
       .--+--.
        \ | /
         \|/
      ~~~~+~~~~
```

> *"Measure twice, cut once — a crate built right is a crate built once."* — the Boatswain

---

## Image vs. Container

- **Image** — the blueprint *and* the parts: a frozen, **read-only** package of a user space.
- **Container** — a **running instance** of an image.
- One image → **many** identical containers. Build once, run anywhere, the same every time.

*The blueprint stays in the drawer. The crates go in the water.*

<!-- The single most common beginner mix-up. Image = noun on the shelf, container = the running thing. -->

---

## Images are built in layers

```text
   harbor.wagbiz.org/raft-fleet/blackbeard:v1

   +------------------------+
   |  COPY index.html       |   your flag        (layer 3)
   +------------------------+
   |  install nginx         |   the web server   (layer 2)
   +------------------------+
   |  FROM alpine           |   a 5 MB base hull (layer 1)
   +------------------------+
```

- Each instruction in the recipe adds **one layer**, stacked bottom-up.
- Layers are **cached and shared** — change only your `index.html`, and only the top layer rebuilds.

---

## The Dockerfile — the blueprint

- The blueprint is a plain-text file: the **`Dockerfile`**.
- A short recipe — for example, `FROM` a base image, then `COPY` your files in.
- Written once; it produces the **exact same image** on any machine, anywhere.

> *We won't drill the syntax on a slide.* In **Lab 01**, the **Socratic Boatswain** — your AI crewmate — coaches you through writing it yourself.

<!-- Deliberately do NOT teach Dockerfile syntax here. The struggle + the Boatswain is the lab's whole pedagogy. -->

---

## The Harbor — where images live

```text
  Dockerfile  --build-->  Image  --push-->  Harbor
  (blueprint)             (crate)           (the docks)
                            |
                            +----run----> Container
                                          (raft afloat)
```

- A finished image needs a home: a **registry** stores and shares images.
- Your island's registry is **Harbor**, at `harbor.wagbiz.org`.
- Build it, push it to the docks, and the cluster can pull it whenever it needs to.

---

## Instructor Superpower

#### The reproducible environment

- This morning's `setup-client.sh` and this afternoon's container are the **same idea at two scales**:
- *describe the environment as code → build it once → hand everyone an identical copy.*
- Containerize an assignment and you ship students the **environment**, not just the code.
- Roughly **90% of "it won't run on my machine"** tickets simply disappear.
- You debug the **image once** — not thirty laptops, forever.

<!-- This is the meta-message of the seminar. Slow down here. The DevOps content is the vehicle; THIS is the destination for a room of educators. -->

---

## Up next: Lab 01 — The First Raft

- Write a **`Dockerfile`** for an Nginx web server.
- Hoist your flag — a custom **`index.html`** with your name on it.
- **Build** the image, **test** that your raft floats, **push** it to Harbor.
- Meet your AI crewmate: the **Socratic Boatswain** (it will *not* hand you the code).

> *Success looks like one thing: your raft afloat and docked in the Harbor — ready for the cluster to find it this afternoon.*

<!-- Send them into the lab with momentum. Read the lab doc on the MkDocs site; create AGENTS.md when prompted. -->

---

<!-- _class: lead -->
<!-- _footer: "" -->

# To the rafts.

```text
        _~
     _~ )_)_~
     )_))_))_)
     _!__!__!_
     \______t/
   ~~~~~~~~~~~~~
```

*The hull is yours. Now build something that floats.*

<!-- Hand off to Lab 01. Point them at lab-01-the-first-raft.md on the docs site. -->
