---
marp: true
auto-scaling: false
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 2 · Gateway API"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 2 · Exposing an App · ~3 minutes

# Gateway API

## Who does what

*Three objects. Three different owners. Knowing which one is **yours** is the whole game.*

<!-- Short interstitial during the Drawing the Fleet lecture, right at the Gateway point — or straight before Lab 03. This is the deck that fixes last session's sticking point: the furthest teams got stuck writing the HTTPRoute because they didn't know which parts of "the gateway" were theirs to write vs. already built for them. Don't teach YAML here — teach roles. The hands-on HTTPRoute anatomy happens live in the demo. -->

---

## The old way put everyone on one wheel

- The classic way to expose an app was a single **Ingress** object.
- It mixed two jobs into one file: **run the front door** (the public IP, the open ports, the TLS certificate) *and* **route my app** (send this hostname to my Service).
- So the IT admin and the app developer were editing the **same object** — stepping on each other, with vendor-specific annotations bolted on.
- **Gateway API splits those two jobs into separate objects, owned by separate people.** That separation *is* the point.

<!-- One slide of contrast so the role-split lands as a fix to a real problem, not trivia. Don't dwell — name the collision, then move to the table. -->

---

## Three objects, three owners

| Object | Who owns it | What it decides |
| :--- | :--- | :--- |
| **GatewayClass** | Infrastructure provider | *What kind* of gateway exists (here: Traefik). Built once. You never see it. |
| **Gateway** | **Cluster operator** | The public IP, which ports are open (80/443), the **TLS cert**, and **who may attach** routes. |
| **HTTPRoute** | **Application developer** | "Traffic for **my** hostname → **my** Service." Lives in *your* namespace. |

- One **Gateway** for the whole cluster. **Many** HTTPRoutes hang off it — one per app.
- Your Service stays **ClusterIP** (internal). The Gateway is the front door; your route is the sign that points visitors to your berth.

<!-- This is the core slide — spend your time here. The shape to leave them with: ONE gateway, MANY routes. The Gateway is shared infrastructure; the HTTPRoute is per-app and disposable. -->

---

## Who's who in *this* room

- **GatewayClass → the platform.** Traefik, installed with the cluster. Already done for you — invisible all week.
- **Gateway → the cluster admin.** This week that's *me*. On a real supported cluster at your college, that's your **IT department**: they stand up `main-gateway` once, wire the DNS, and load the wildcard TLS cert.
- **HTTPRoute → you.** In Lab 03 you write **one HTTPRoute** for your frontend — and *nothing else* about the gateway. You don't touch the IP, the ports, or the cert. You file a route; the front door was already built.

<!-- Make it personal. Point at yourself for "cluster admin," point at the room for "HTTPRoute." The relief is the message: the scary 80% of "the gateway" is not your job — IT owns it. You write the small, safe part. -->

---

<!-- _class: lead -->

# The takeaway

## IT builds the gateway **once**. Every developer just **files a route** against it.

*That clean split between operator and developer is the entire reason Gateway API exists.*

<!-- Hand off to the demo: "Watch me write that one HTTPRoute live and wire the Radar tier to the front door." -->
