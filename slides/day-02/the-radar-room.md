---
marp: true
auto-scaling: false
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 2 · The Radar Room"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 2 · Lecture 1 · 70 minutes

# The Radar Room

## Kubernetes Architecture, Deployments & k9s

*Yesterday you launched a Pod. Today you meet the harbour-master who runs the whole island.*

<!-- Welcome them to Day 2. They left yesterday with a Pod afloat in the cluster. This lecture pays off that investment by explaining the machinery underneath it and teaching them to operate it like a professional. Keep it energetic; the labs are live and active today. -->

---

## Where we are

- Yesterday you launched a **bare Pod** into the cluster — the smallest thing Kubernetes can run.
- The next 70 minutes: the full picture of what keeps that Pod alive, and the tools to see it.
- Four parts:
  - **Part I** — Meet Captain Kube (Kubernetes architecture)
  - **Part II** — From Pod to Deployment (resilience and self-healing)
  - **Part III** — Config lives off the ship (ConfigMaps)
  - **Part IV** — The Radar Room (k9s)
- Then the labs: **Lab 01** (find the broken ship) and **Lab 02** (build a resilient fleet).

<!-- Frame this as the "why did that work?" lecture for everything they did yesterday. The architecture is not abstract theory — every piece maps directly to what they'll touch in the labs today. -->

---

<!-- _class: chapter -->

#### Part I

# Meet Captain Kube

```text
          |\          |\
          | \         | \
          |  \        |  \
          |   \       |   \
       ___|____\______|____\___
       \                      /
        \   A D M I R A L     /
         \____________________/
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

> *"The harbour-master sees every ship, every berth, every tide. That's not power — that's paperwork done right."* — the Boatswain

---

## The island's harbour-master

- On Day 1 you ran `kubectl apply` and a Pod appeared. Something made that happen.
- **Kubernetes** is the orchestrator running the island — the book calls it **Captain Kube**.
- Captain Kube has two halves:
  - the **Control Plane** — the harbour office that makes decisions
  - the **Worker Nodes** — the ships that carry the cargo
- Everything you do with `kubectl` is a message to the harbour office.

<!-- Anchor this to Day 1: they already talked to Captain Kube. Now they learn what they were actually talking to. The harbour metaphor carries through the whole part — lean on it. -->

---

## The Control Plane — the harbour office

```text
  +------------------------------------------------+
  |               CONTROL PLANE                    |
  |                                                |
  |   API Server      etcd         Scheduler       |
  |   (harbour        (ship's      (berth          |
  |    office)         register)    master)         |
  |                                                |
  |          Controller Manager                    |
  |          (the reconcile crew)                  |
  +------------------------------------------------+
```

- Four components, one purpose: keep the cluster matching what you asked for.

<!-- Draw attention to each box — you'll explain each one on the next four slides. Don't linger here; this is a roadmap, not the destination. -->

---

## The API Server — harbour office counter

- **Every** request goes through the API Server — `kubectl`, the scheduler, the controllers, all of them.
- It is the single front door to the cluster.
- It validates your manifest, stores the result in etcd, and notifies the rest of the system.
- Think of it as the clerk at the harbour office: nothing moves without a stamp from this counter.

<!-- Concrete question to ask the room: "When you ran kubectl apply yesterday, where did that command go?" The answer is: straight to the API Server. -->

---

## etcd — the ship's register

- The API Server writes every decision to **etcd** — a distributed key-value store.
- etcd is the cluster's **memory of desired state**: what you asked for, and what currently exists.
- If the whole control plane rebooted right now, etcd would bring it back to exactly where it was.
- One ledger. Every manifest ever applied lives here.

*The crew can change; the ship's log endures.*

<!-- Analogy: a harbour's handwritten ledger of every registered vessel, updated the moment a ship enters or leaves. etcd is that ledger, but it never burns. -->

---

## The Scheduler — the berth master

- A new Pod lands in etcd: "I need a home." The **Scheduler** finds it one.
- It looks at every worker node: How much CPU and memory is free? Any constraints on this Pod?
- It picks the best berth and writes the decision — "Pod X goes to Node 3" — back to the API Server.
- The Scheduler never moves cargo itself. It only assigns berths.

<!-- The scheduler is purely declarative: it reads desired state from etcd and writes a placement decision back. It does not SSH into nodes. That part is the kubelet's job, coming up shortly. -->

---

## The Controller Manager — the reconcile crew

- A fleet of background workers, each watching one type of resource.
- Their job: compare **desired state** (what's in etcd) with **actual state** (what's running).
- If they differ, act. If they match, do nothing.
- The Deployment controller, the ReplicaSet controller, the Node controller — all live here.

> This loop never stops. Desired ≠ actual → fix it. That is the whole job.

<!-- This is the most important concept in all of Kubernetes. The reconcile loop is why Kubernetes feels "self-healing." It's not magic — it's a very diligent crew checking their list every few seconds. -->

---

## Worker Nodes — the ships

```text
  +-------------------------------+
  |         WORKER NODE           |
  |                               |
  |   kubelet   (the boatswain)   |
  |   kube-proxy (signal flags)   |
  |   Container Runtime (Docker)  |
  |                               |
  |   [ Pod ]  [ Pod ]  [ Pod ]   |
  +-------------------------------+
```

- Each worker node is a machine (physical or virtual) that runs Pods.
- The **kubelet** is the boatswain on each ship: it receives orders from the control plane and carries them out.
- Every node reports its health back to the API Server continuously.

<!-- In your classroom: every student's workload lands on one of these nodes. The cluster has several; the scheduler decides which one. -->

---

## The kubelet — the boatswain on deck

- The kubelet runs on every worker node. It does not run on the control plane.
- Its job: watch for Pods assigned to its node, start them, and keep them running.
- If a container crashes, the kubelet restarts it — immediately, without being asked.
- It reports the Pod's status back to the API Server so etcd stays current.

*The boatswain doesn't question orders. A Pod is assigned — it runs it. A container dies — it restarts it.*

<!-- Contrast with the scheduler (which assigns berths) and the controller manager (which watches the whole fleet). The kubelet watches only its own ship. -->

---

## The reconcile loop — tied back to Day 1
<!-- _class: diagram-xs -->

```text
  You run: kubectl apply -f pod.yaml
                  |
                  v
         API Server receives it
                  |
                  v
         etcd stores DESIRED STATE
                  |
                  v
  Scheduler assigns a Node
                  |
                  v
  kubelet on that Node starts the Pod
                  |
                  v
  Controllers watch: actual == desired? -> yes -> rest
```

- This loop runs **continuously**. Drift from desired state is corrected automatically.

<!-- "Declarative" from Day 1 now has a mechanism. You wrote down what you want; this loop is what enforces it. -->

---

<!-- _class: chapter -->

#### Part II

# From Pod to Deployment

```text
            .---.
            ( o )
            '-+-'
              |
          .   |   .
           \  |  /
         '. \ | / .'
           '.\|/.'
         ~~~~~'~~~~~
```

> *"One crate afloat is a start. A standing order that keeps three afloat is a fleet."* — the Boatswain

---

## The bare Pod's fatal flaw

- On Day 1 you ran a bare Pod — one manifest, one container, one copy.
- It has no safety net: if the node it lives on goes down, **the Pod stays dead**.
- No one restarts it. No one moves it. The controller manager has nothing to watch.
- A bare Pod is fine for learning. It is not how you run anything that matters.

*A lone ship with no relief crew is not a fleet — it's a gamble.*

<!-- This is not a criticism of Day 1's lab — it was the right starting point. Now they understand *why* we move past it. -->

---

## A Deployment: the standing order

- A **Deployment** is a standing order to the cluster:
  - *"Always keep N copies of this Pod afloat."*
- You describe the Pod template and the replica count. The Deployment controller does the rest.
- The controller manager's Deployment controller watches it continuously.
- Lose a Pod — the controller notices within seconds and schedules a replacement.

> You stop managing individual Pods. You manage the *order* instead.

<!-- The mental shift: from "I deployed a Pod" to "I declared a desired state for a fleet of Pods." -->

---

## The ReplicaSet underneath

```text
  Deployment
     |
     +-- ReplicaSet  (current version of the template)
              |
              +-- Pod   (replica 1)
              +-- Pod   (replica 2)
              +-- Pod   (replica 3)
```

- A Deployment manages a **ReplicaSet**. A ReplicaSet manages a set of identical Pods.
- You interact with the Deployment. The ReplicaSet is the machinery underneath.
- You rarely need to touch a ReplicaSet directly — the Deployment does it for you.

<!-- Practical note: kubectl get replicasets shows them. Worth glancing at once in k9s to see the layer. -->

---

## Self-healing in practice

- Delete one of the three Pods manually — watch what happens in k9s.
- The ReplicaSet controller notices: *actual = 2, desired = 3.*
- Within seconds, a new Pod is scheduled and started.
- You didn't do anything. The reconcile loop did.

```bash
  kubectl delete pod my-fleet-abc123   <- you delete one
  # 5 seconds later...
  kubectl get pods                     <- three are running again
```

<!-- This is the live demo moment in Lab 01's CrashLoop triage. They will see self-healing happen in real time. Plant the vocabulary now. -->

---

## Scaling: change the order

- Need more ships? Change one number.

```bash
  kubectl scale deployment my-fleet --replicas=5
```

- The Deployment controller sees: *desired = 5, actual = 3.* It schedules two more Pods.
- Scale back down: two Pods are gracefully terminated.
- No downtime. No rebuild. No manual work.

*The harbour-master doesn't ask why. It just keeps the count right.*

<!-- Contrast with a monolith: "need more capacity" meant ordering a whole new server. Here it's one command. -->

---

## Rolling updates — no downtime

- Update your image tag in the Deployment manifest and apply it.
- Kubernetes replaces Pods **one at a time**, not all at once:
  - start one new Pod → wait for it to be healthy → terminate one old Pod → repeat
- Traffic keeps flowing through the live Pods while the swap happens.
- Roll it back just as easily if the new version misbehaves.

*Like rotating a ship's crew at port — the ship never stops sailing.*

<!-- Brief is right here — rolling updates are important but not the focus of today's lab. One slide, clear mental model, move on. -->

---

<!-- _class: chapter -->

#### Part III

# Config Lives Off the Ship

```text
        .-=======-.
       / | | | | | \
       | | | | | | |
       | | | | | | |
       \ | | | | | /
        '-=======-'
```

> *"A sailor who paints his orders on the hull can't change course without a chisel."* — the Boatswain

---

## The problem with baked-in config

- The obvious place to put config is **inside the container image**.
- Hard-code `SHIP_SPEED=12` in the Dockerfile, build the image, done.
- Until the value changes. Now you:
  - edit the file
  - rebuild the image
  - push to Harbor
  - update the Deployment
  - wait for a rolling restart
- One config line change. Full rebuild pipeline.

<!-- This is the concept made concrete: changing one environment variable should not mean touching five systems. That is the pain ConfigMaps remove. -->

---

## The fix: a ConfigMap

- A **ConfigMap** stores configuration **in the cluster** — outside the image.
- It is just a Kubernetes object: key-value pairs you apply with `kubectl apply`.
- Your Deployment references it; the kubelet injects the values when it starts the Pod.
- Change the ConfigMap and roll the Deployment — **no image rebuild**.

```text
  ConfigMap               Deployment
  MESSAGE_OF_THE_DAY  --> injected as env var --> Pod sees it
  SHIP_SPEED          --> injected as env var --> Pod sees it
```

<!-- Same image, different config, different environment. Dev, staging, prod — all the same container, each with its own ConfigMap. -->

---

## What a ConfigMap looks like

```text
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: fleet-config
  data:
    MESSAGE_OF_THE_DAY: "Beware the Kraken!"
    SHIP_SPEED: "12"
```

- `kind: ConfigMap` — Kubernetes knows what this is.
- `data:` — plain key-value pairs. No encryption, no secrets. Just config.
- Apply it like any other manifest: `kubectl apply -f configmap.yaml`

<!-- Don't teach the full injection syntax here — the lab does that with the Boatswain's help. The point is: it's just another Kubernetes object. -->

---

## Injecting it into a Deployment

```text
  containers:
  - name: web
    image: nginx:alpine
    env:
    - name: MESSAGE_OF_THE_DAY
      valueFrom:
        configMapKeyRef:
          name: fleet-config
          key: MESSAGE_OF_THE_DAY
```

- Each env var you want gets one `valueFrom` block.
- The kubelet reads the ConfigMap and injects the value when it starts the container.
- **Same image. Different ConfigMap. Different behaviour per environment.**

<!-- The lab has them write this with the Boatswain guiding them. Don't drill the syntax — just make sure they understand the shape of it. -->

---

## Why this matters for educators

- Containerize an assignment: the image is the problem set.
- The ConfigMap is the per-student variation: different parameters, different data, different challenge.
- Same image, thirty ConfigMaps, thirty distinct experiences — **no per-student rebuild**.
- The IT department isn't in this loop at all.

*The lesson is a standing order. The parameters live off the ship.*

<!-- This is the educator payoff hidden inside Part III: you control the config yourself — no image rebuild, no waiting on IT. -->

---

<!-- _class: chapter -->

#### Part IV

# The Radar Room

```text
       .---------------.____
      [ :::::::::::::::: ]__ )
       '---------------'
```

> *"A good navigator doesn't squint at every rope. He climbs the lighthouse and reads the whole harbour."* — the Boatswain

---

## kubectl works — but it's verbose

- `kubectl` is powerful and precise. It is also one command per question.
- Want to watch Pod status live? `kubectl get pods --watch`
- Want to see logs? `kubectl logs <pod-name>`
- Want to exec in? `kubectl exec -it <pod-name> -- sh`
- Each is its own command. Each requires knowing the exact Pod name. Each produces raw text.
- When you're debugging under pressure, this gets tedious fast.

<!-- Validate the tool they already know before introducing the new one. kubectl is not going away — k9s sits on top of it. -->

---

## Meet k9s — the terminal dashboard

```text
  +--------------------------------------------------+
  |  k9s  |  Cluster: uss-nitic   |  NS: your-name  |
  +--------------------------------------------------+
  |  NAME             READY  STATUS   RESTARTS  AGE  |
  |  my-fleet-abc12   1/1    Running  0         2m   |
  |  my-fleet-def34   1/1    Running  0         2m   |
  |> my-fleet-ghi56   0/1    Error    3         45s  |
  +--------------------------------------------------+
  |  l=logs  s=shell  d=describe  ctrl-d=delete      |
  +--------------------------------------------------+
```

- **k9s** is a terminal UI (TUI) — a live, interactive dashboard for your whole cluster.
- One screen. Every Pod. No typing of names.

<!-- k9s is already installed on every VM. No setup step needed today. -->

---

## Navigating k9s

- Launch it: type `k9s` and press Enter.
- `:ns` — switch to the namespace list; arrow-key to yours and Enter.
- `/` — filter: type any string to narrow the view instantly.
- Arrow keys to highlight a Pod, then:
  - `l` — view **logs** (live-streaming)
  - `s` — **shell** into the Pod (exec)
  - `d` — **describe** the Pod (events, conditions)
  - `Ctrl-d` — **delete** the Pod
- `Esc` to back up one level. `q` to quit.

<!-- Walk this live on the projector before the lab. Two minutes of demo beats ten minutes of students reading key-bindings from a doc. -->

---

## Reading the radar: Pod status at a glance

| Status | What it means |
|---|---|
| `Running` | All containers alive and healthy |
| `Pending` | Scheduler hasn't placed it yet |
| `CrashLoopBackOff` | Container keeps crashing; K8s keeps restarting |
| `Error` | Container exited with a non-zero code |
| `Terminating` | Being gracefully shut down |

- k9s colour-codes these. `CrashLoopBackOff` stands out immediately.
- When you see it: press `l` and read the logs — the answer is almost always there.

<!-- This table is the triage guide for the CrashLoop diagnosis coming up in Lab 01. Make sure every person in the room has this in their head before they open k9s. -->

---

## The log view

- Highlight a Pod, press `l` — logs stream live from the container.
- `s` key toggles auto-scroll on and off (useful when the output is fast).
- Arrow keys scroll up through older output.
- `Esc` returns you to the Pod list.

*The error message is almost always in the last few lines of the log.*

```text
  leaky-ship: starting up...
  leaky-ship: ERROR: cat: can't open '/nonexistent/config.txt'
  leaky-ship: exiting.
```

<!-- Don't reveal the full error string — just show the shape of it. The Speed Round's payoff is them reading it themselves. -->

---

## Exec — boarding the ship

- Highlight a Pod, press `s` — an interactive shell opens **inside** the container.
- Useful for:
  - checking that env vars injected from a ConfigMap actually arrived
  - poking at the filesystem
  - running quick diagnostics without leaving the cluster
- `exit` to leave the shell and return to k9s.

```text
  # inside the pod
  env | grep MESSAGE
  MESSAGE_OF_THE_DAY=Beware the Kraken!
```

<!-- This is Step 4 of Lab 02 — verifying the ConfigMap injection. Plant it here so the lab step feels familiar. -->

---

## Instructor Superpower

#### The Teacher's Dashboard

- Once students know k9s, the instructor gains something more valuable: **full visibility from the podium**.
- Type `/` then a student's namespace name — their Pods, status, and logs appear instantly.
- No walking the room. No leaning over shoulders. No "can you share your screen?"
- A student's Pod in `CrashLoopBackOff`? You see it before they raise their hand. Spot the same error on three screens — address it once, for the room.
- This kind of visibility used to be a request to IT. Now it's one terminal on a cluster you already run.
<!-- This is the destination for a room of educators. Slow down. You asked IT for a cluster, not for per-student tooling — k9s gives you everything on top of that one shared resource. If you want a closer, ask them yourself: concept, or maintenance? -->

---

## Up next: the labs

**Lab 01 — The Radar Room** *(right after this)*

- Open k9s. Navigate to your namespace.
- A rogue wave has hit the fleet — a broken Pod is waiting in your namespace.
- Find it, read the logs, identify the exact error.
- Then try to delete it with `Ctrl-d`. See what happens.

**Lab 02 — Deploying the Fleet** *(after the break)*

- Generate a Deployment manifest with `kubectl create --dry-run`.
- Scale it to 3 replicas. Watch self-healing happen live.
- Create a ConfigMap with `MESSAGE_OF_THE_DAY`, inject it into the Deployment.
- Verify inside the running Pod with `env | grep MESSAGE`.

<!-- Send them in with energy. The CrashLoop triage is concrete — they'll know immediately whether they've read the logs right. Lab 02 builds on every concept from today's lecture. -->

---

<!-- _class: lead -->
<!-- _footer: "" -->

# To the radar room.

```text
         \  .  /
        '-.[O].-'
           |=|
          /| |\
         / |#| \
        /  | |  \
       /___|_|___\
     ~~~~~~~~~~~~~~~~
```

*The harbour is alive. Open k9s and read the water.*

<!-- Hand off to Lab 01. Point them at lab-01-the-radar-room.md on the docs site. Triage starts the moment they open k9s. -->
