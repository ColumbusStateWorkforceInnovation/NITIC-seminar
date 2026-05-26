---
marp: true
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 1 · Into the Deep"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 1 · Lecture 2 · 45 minutes

# Into the Deep

## From Containers to Kubernetes Pods

*Your raft is built. Now we launch it into open water.*

<!-- They are coming off Lab 01 with an image pushed to Harbor. Energy is usually good here — they just made something. This lecture is the bridge to the cluster. Keep it tight: 45 minutes, then the flash poll, then Lab 02. -->

---

## Where we are

- Lab 01 is done — you have a container **image** sitting in Harbor.
- That's a raft, built and beached. It doesn't sail itself.
- The next 45 minutes: how Kubernetes takes that image and puts it to sea.
- Four short legs:
  - Why one container isn't a fleet
  - The **Pod** — what Kubernetes actually runs
  - Declaring what you want, instead of hand-steering
  - Why Pods are built to be thrown away
- Then a quick flash poll, and **Lab 02 — Paddling Out**.

<!-- Set the scope. We are not teaching all of Kubernetes today — just enough to launch one Pod and read its logs. The full tour of Captain Kube is tomorrow morning. -->

---

<!-- _class: chapter -->

#### Part I

# Why a Raft Isn't a Fleet

```text
            |\
            | \
            |  \
            |   \
            |    \
         ___|_____\___
         \           /
          \_________/
       ~~~~~~~~~~~~~~~~~
```

> *"One raft is a tale. A fleet is a future. Ye can't crew the whole ocean alone."* — the Boatswain

---

## One container, one problem

- On your VM you can already do this:  `docker run my-raft`
- It works — until it doesn't:
  - the container **crashes** and stays down
  - the **host reboots** and nothing comes back
  - you need **ten** copies, not one
  - the machine it runs on fails, and it has to move
- A lone container has nothing watching it. Something has to — and "a person doing it by hand" is not a plan that survives contact with reality.

<!-- Let this land. A single container is a great building block and a terrible production strategy. The pain is operational, not conceptual. -->

---

## You need a harbour-master

- Something that watches every container and **keeps the fleet sailing**:
  - restarts the ones that sink
  - schedules them across whatever machines you have
  - scales them up and down on demand
  - replaces them when a whole machine is lost
- That something is an **orchestrator**.

<!-- The orchestrator is the answer to every "who does that?" from the previous slide. Name the role before you name the tool. -->

---

## Meet the orchestrator: Kubernetes

- **Kubernetes** is the orchestrator the island runs on — the book calls it **Captain Kube**.
- You hand Captain Kube your containers and a description of what you want.
- It makes the ocean **match that description** — and keeps it matching.
- *We meet Captain Kube properly tomorrow morning.* Today: just enough to paddle out.

<!-- Deliberately do not open up the full K8s architecture here — that is Day 2's first lecture. Today is a single Pod, start to finish. -->

---

## The real shift: telling vs. asking

- **Docker** is *imperative* — "run this container, right now." A one-time order.
- **Kubernetes** is *declarative* — "I want one of these to **always** exist."
- You describe the **destination**. The cluster does the steering, continuously.
- Pull a Pod out from under it, and Kubernetes notices and acts.

> Stop hand-steering every wave. Hand over the chart and let the crew hold course.

<!-- Imperative vs declarative is THE mental model for the rest of the seminar. If they only keep one idea from Part I, this is it. -->

---

<!-- _class: chapter -->

#### Part II

# A Life-Jacket Called a Pod

```text
        .-"""""-.
      .'  _____  '.
     /   /     \   \
    |   |       |   |
     \   \_____/   /
      '.         .'
        '-.....-'
```

> *"Never send a crate to sea without a life-jacket. The deep don't forgive."* — the Boatswain

---

## Kubernetes doesn't run containers

- Here's the surprise: the smallest thing Kubernetes runs is **not** a container.
- It's a **Pod**.
- A raw container is just a box. Kubernetes wraps that box in a life-jacket — and the life-jacket is what it actually schedules, watches, and restarts.

<!-- This genuinely surprises people who come in from Docker. Pause on it. You never say "run my container" to Kubernetes; you say "run my Pod." -->

---

## So what is a Pod?

- A **Pod** is the smallest deployable unit in Kubernetes.
- It wraps **one — or more — containers** that are always:
  - **scheduled together**, on the same machine
  - **started and stopped together**, sharing one lifecycle
  - **networked together**, sharing one address
- Most Pods hold exactly **one** container. But the wrapper can hold more — and that turns out to be useful.

<!-- "One or more" is the phrase the flash poll checks. Say it clearly. -->

---

## Why wrap it? Containers in a Pod share

```text
  +------------------ POD -------------------+
  |   one IP address  .  one localhost       |
  |                                          |
  |   [ main container ]   [   sidecar   ]   |
  |                                          |
  |   +----------------------------------+   |
  |   |       shared storage volume      |   |
  |   +----------------------------------+   |
  +------------------------------------------+
```

- One **IP address** for the whole Pod — containers inside reach each other on `localhost`.
- Shared **storage** — they can hand files back and forth.
- One **lifecycle** — born together, die together.

---

## The sidecar pattern

- Most Pods are one container. But you can add a **helper** alongside it:
  - a **log shipper** that forwards your app's logs
  - a **proxy** that handles encryption or routing
  - a **file-syncer** that pulls in fresh content
- Main container + sidecar, sharing one Pod's network and storage.
- The app stays simple; the helper does the plumbing — **without changing your image**.

<!-- Sidecars are why the Pod exists at all. Optional depth — if time is short, one sentence and move on. The flash poll only needs "shares network and storage." -->

---

## Pod vs. Container

| | **Container** | **Pod** |
|---|---|---|
| What it is | a packaged process | Kubernetes' smallest unit |
| Holds | one application | one *or more* containers |
| Network | (on its own) | one shared IP address |
| You... | **build** it (Lab 01) | **deploy** it (Lab 02) |

*You build containers. You deploy Pods. The Pod is the box Kubernetes can actually carry.*

<!-- This table is the summary of Part II. The flash poll's Pod question maps straight onto the "Holds" and "Network" rows. -->

---

<!-- _class: chapter -->

#### Part III

# Charts, Not Hand-Steering

```text
               N
            .  |  .
             \ | /
        W .----+----. E
             / | \
            .  |  .
               S
```

> *"Hand the sea a good chart and it'll hold your course while ye sleep."* — the Boatswain

---

## Kubernetes objects are written down

- Everything in Kubernetes — a Pod included — is described in a **manifest**: a **YAML** file.
- YAML is just structured text: keys, values, indentation.
- A Pod manifest can run 30+ lines, and it **looks** intimidating.
- Good news, and the rule for this whole seminar:

> **You do not write Kubernetes YAML from memory. You generate it.**

<!-- Quote the lab's pedagogical note verbatim: "No one memorises Kubernetes YAML. We generate it." This lowers the anxiety in the room immediately. -->

---

## Generate, don't memorise

```text
kubectl run my-raft \
  --image=harbor.wagbiz.org/raft-fleet/<your-name>:v1 \
  --dry-run=client -o yaml > pod.yaml
```

- `--dry-run=client` — *"build the manifest, but don't create anything yet."*
- `-o yaml` — print it as YAML.
- `> pod.yaml` — save it to a file you can open and read.
- Kubernetes just wrote your manifest **for** you.

<!-- This exact command is flash-poll Question 3 and Step 2 of Lab 02. Walk it left to right. The trap answers swap in 'generate', 'create ... pod', or 'docker'. -->

---

## The workflow: generate, read, apply

```text
   1. GENERATE          2. READ / EDIT         3. APPLY
   -----------          --------------         -----------
   kubectl run     -->  open pod.yaml      --> kubectl apply
   --dry-run=client     plain, readable        -f pod.yaml
   -o yaml > pod.yaml   YAML you can tweak      => Pod is live
```

- You never face a blank file. You start from a working draft.
- Read it, adjust it if you need to, then **apply** it to the cluster.

<!-- The generator is the safety net. They edit a real example instead of authoring YAML cold. -->

---

## Claim your territory: Namespaces

- One cluster. Around **thirty** sailors sharing it.
- A **Namespace** is your own patch of ocean — your work, walled off from everyone else's.

```text
kubectl create namespace <your-name>
kubectl config set-context --current --namespace=<your-name>
```

- The second line says *"always work in my patch"* — so you stop typing `-n` every time.
- Your `my-raft` Pod and your neighbour's never collide.

<!-- Namespaces are Step 1 of Lab 02. They are also the backbone of the instructor superpower coming up — flag that this slide matters. -->

---

## Seeing the whole ocean

- `kubectl get pods` — the Pods in **your** namespace.
- `kubectl get pods -A` — **every** Pod, in **every** namespace, across the whole cluster.
- That `-A` flag is how you see past your own patch of water.
- Keep it in your back pocket — Lab 02 ends with a reason to need it.

<!-- 'kubectl get pods -A' is flash-poll Question 5. Lab 02 ends with a hunt across namespaces — just plant the command here, don't spoil the activity. -->

---

<!-- _class: chapter -->

#### Part IV

# Ghost Ships

```text
          .-~~~~~-.
         / (o) (o) \
         \    <    /
        .-'~~~~~~~'-.
       / / / | \ \ \ \
      ( ( (  |  ) ) ) )
       \_\_\_|_/_/_/_/
```

> *"You best start believing in ghost stories, Miss Turner... you're in one."* — Captain Barbossa, *Pirates of the Caribbean: The Curse of the Black Pearl*

---

## Cattle, not pets

- A Pod is **disposable** — by design.
- It can crash, be rescheduled to another machine, or be replaced at any moment.
- That is not a failure. That is Kubernetes **keeping the chart matched**.
- So: don't name it, don't nurse it, don't hand-tune it. **Don't grow attached.**

<!-- "Cattle, not pets" is industry shorthand worth giving them. The emotional shift is real: a Pod dying is normal weather, not an incident. -->

---

## The Ghost Ship

```text
  kubectl exec into a running Pod
        |
        +--  hand-edit a file inside it      (looks fine!)
        |
  kubectl delete pod  +  kubectl apply -f pod.yaml
        |
        v
  the hand-edit is GONE - rebuilt from the immutable image
```

- Changes you make **inside** a running Pod live only in that Pod.
- Delete it, recreate it from `pod.yaml`, and those changes **vanish**.

> If it isn't baked into the **image** or written in the **manifest**, it will sink.

<!-- This is the demo you run live in Lab 02 (the Ghost Ship). It is also flash-poll Question 4. Tell them to watch for it this afternoon. -->

---

## Your diagnostic spyglass

When a Pod misbehaves, three commands tell you almost everything:

```text
kubectl get pods              is it running? what's its status?
kubectl logs <pod>            what did the container print?
kubectl exec -it <pod> -- sh  board the Pod and look around
```

- `get` for the **status**, `logs` for the **story**, `exec` to **walk the deck**.
- You'll use all three in Lab 02 — and lean on them all week.

<!-- These three are the entire debugging toolkit for today. Day 2 adds k9s on top, but the commands underneath never change. -->

---

## Instructor Superpower

#### One cluster, thirty safe sandboxes

- Every student's work is two things you can **see**: a readable **manifest** and an isolated **namespace**.
- A student stuck? `delete` the Pod, re-`apply` the file — a clean reset in seconds.
- The real shift: the environments you can *choose* to support have radically expanded. You don't wait for IT to say "sure, we can support that" — you build it yourself, for a lesson, a project, a whole course.
<!-- This is the destination slide for a room of educators. The declarative model turns "debug a mystery laptop" into "re-apply a known file." Slow down. If you want a closer, put it to the room yourself: are you teaching the concept, or the maintenance? -->

---

## Up next: Flash Poll, then Lab 02

- **Flash poll** — five quick questions to check the crew before we sail. Open `poll.wagbiz.org`.
- Then **Lab 02 — Paddling Out**:
  - board the live cluster with your Rancher kubeconfig
  - claim your **namespace**
  - **generate** `pod.yaml`, then `apply` it
  - practise the spyglass: `logs` and `exec`

> Outcome: your raft afloat in the live cluster — and you, able to tell why when it isn't.

<!-- The flash poll is a comprehension gauge, not a contest — read the results to decide how much to demo before the lab. Then point them at lab-02-paddling-out.md on the docs site. -->

---

<!-- _class: lead -->
<!-- _footer: "" -->

# Paddle out.

```text
        _~
     _~ )_)_~
     )_))_))_)
     _!__!__!_
     \_______/
   ~~~~~~~~~~~~~
```

*The raft is yours. The ocean is the cluster. Go.*

<!-- Hand off to the flash poll, then Lab 02. -->
