---
marp: true
auto-scaling: false
theme: nautical
paginate: true
size: 16:9
footer: "Admiral Bash's Island Adventure  ·  Day 3 · All Hands on Deck"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

#### Day 3 · Collaboration Playbook · short talk-through

# All Hands on Deck

## Turning one cluster into a crew

*You ran the sabotage in the lab. Here's the rest of the fleet of ways to set the crew loose on each other — and the platform-engineering twist underneath.*

<!-- This is a short, talk-through deck — not a lecture with a lab. The room has just done the ArgoCD sabotage-and-self-heal in Lab 02. Use this to (1) show them the menu of other collaborative scenarios they could run with their own students, and (2) land the platform-engineering "division of labor" idea with concrete examples. Pace: fast. One example per slide, talk it, move on. -->

---

## The rule that makes it safe

```text
   kubectl is a suggestion.        Git is the law.
   ───────────────────────        ──────────────
   live edits heal away           a merged commit sticks
```

- Give students **broad rights** in the cluster *and* keep every app **GitOps-managed with self-heal on.**
- Now collaboration can't break anything permanently: a live edit by a neighbor is **graffiti that heals**, the repo is the only thing that lasts.
- That single guarantee is what lets you say *"go ahead — delete each other's stuff."*

> Every scenario in this deck rides on that one rule.

<!-- This is the load-bearing slide. The whole point: broad rights are only safe because GitOps reverts anything not written in Git. Say it plainly — it's also the deepest GitOps lesson of the day. Once they believe this, every collaborative scenario is unlocked. -->

---

## Already in the lab: Sabotage & Self-Heal

- The official one — they just did it.
- *"With the rights the Admiral granted you, go delete a **crewmate's** deployment."*
- Their neighbor's ArgoCD hauls it back within seconds. You **cannot win against someone else's Captain's Log.**
- The takeaway, out loud: *"So how do you actually change a crewmate's fleet? You don't touch their cluster — you change their law."* → which is the next slide.

<!-- This recaps what they just lived in Lab 02 and uses it as the springboard. The rhetorical question at the end is the hinge into the PR Raid: you've shown them the destructive pole; now show them the constructive one. -->

---

<!-- _class: chapter -->

#### The menu

# Set the crew loose

```text
      \o/   \o/   \o/   \o/
       |     |     |     |
      / \   / \   / \   / \
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   one cluster · many hands
```

> *Four more ways to make thirty people one crew.*

---

## 1 · The PR Raid  *(the constructive twin)*

**Move:** open a pull request against a *neighbor's* Gitea repo.

- Add a `readinessProbe`. Bump replicas. Fix a missing label.
- The owner **reviews and merges** → ArgoCD ships it → it **sticks.**
- Vandalism heals away; a **merged PR lasts.** Both poles of "Git is the law," felt back to back.

> *You can't change my cluster. You can propose a change to my law.*

<!-- The single best complement to the sabotage — same Gitea + ArgoCD plumbing, near-zero setup. It teaches the positive face of GitOps collaboration: review, merge, ship. Run it right after the sabotage and the contrast does all the teaching. -->

---

## 2 · The Chain Reaction  *(one organism)*

**Move:** wire each student's app to call the **next crew's** Service.

- A ring: your frontend → your right-hand neighbor's backend.
- Someone deletes their deployment — the break **ripples downstream** — then self-heal restores the whole chain.
- *Your uptime is my uptime.* Teaches cross-namespace Services & DNS.

> Bonus: it's the perfect Day 4 on-ramp — the Pirate breaks one node and the blast propagates.

<!-- Bigger swing because it adds networking, but it's the most memorable: the room becomes a single connected system. Great if the room is flying and you want one "we're all connected" beat before Day 4. Skip if time is tight. -->

---

## 3 · The Town Square  *(the shared artifact)*

**Move:** one shared namespace with a guestbook / leaderboard.

- Every student's chart deploys **one tile** into it via their own ArgoCD app.
- The picture is only complete when **all thirty** are synced.
- Delete the town-square app and *everyone's* contribution vanishes — then GitOps brings it all back.

> The most *visual* whole-room moment. Take the photo.

<!-- The crowd-pleaser. It's a single collective artifact that visibly assembles as the room syncs, and collapses/restores on cue. Lower stakes than the Chain Reaction, high payoff for engagement. -->

---

## 4 · Fix My Broken Chart  *(collaborative debugging)*

**Move:** everyone plants a bug, then swaps repos.

- Break your own chart — bad indent, wrong `.Values` ref, image typo.
- Push it; ArgoCD flips to **Degraded.**
- Hand the repo to a neighbor to **diagnose and fix via PR.**
- Teaches `helm template`, reading ArgoCD's error states, and `helm lint`.

> Pairs naturally with the PR Raid — same workflow, opposite intent.

<!-- Pure troubleshooting fun, and it builds the debugging muscle they'll need on Day 4. The planted-bug-then-swap format guarantees everyone both breaks and fixes something. -->

---

<!-- _class: chapter -->

#### The idea underneath

# Division of Labor

```text
   produce  ──▶  consume  ──▶  verify
   (build it)   (use it)     (guard it)
```

> *A platform team doesn't make everyone build everything.*

---

## Platform engineering is a relay, not a solo

- On a real platform team, the work **splits by role:**
  - someone **produces** a reusable thing (a paved road),
  - others **consume** it (self-service, no internals),
  - others **verify & guard** it (tests, policy, scans).
- Assign those three roles across a crew and **your classroom becomes a platform team** — each student feels a different seat.
- The next three slides are the same pattern, three different "things."

<!-- This is the conceptual heart and the answer to Eric's ask. The produce/consume/verify relay IS platform engineering in miniature. The pedagogical move is role assignment: A/B/C each occupy a different platform seat, so the collaboration teaches the org structure, not just the tool. -->

---

## A → B → C · The Reusable Workflow

| Seat | Student | Does |
| :--- | :--- | :--- |
| **Produce** | A | Authors a CI **workflow** (Gitea Actions / Argo `WorkflowTemplate`) — build, tag, push. |
| **Consume** | B | **Uses** it from their own repo: `uses: A/ci-workflows/build@v1`. Never rewrites it. |
| **Verify** | C | Writes the **tests** that keep it honest — a sample repo + assertions that fail if A's workflow breaks. |

> One pipeline, authored once, consumed by the whole crew, guarded by a third hand. *That's a platform.*

<!-- This is Eric's named example, formalized. The key teaching point: B never sees the workflow internals — that's the golden path working. C's tests are the guardrail that lets A change the workflow without breaking B. Name all three seats out loud. -->

---

## A → B → C · The Golden Helm Chart

| Seat | Student | Does |
| :--- | :--- | :--- |
| **Produce** | A | Publishes a parameterized chart to Harbor: `helm push stack.tgz oci://harbor.../charts`. |
| **Consume** | B | Installs it with **their own** `values.yaml` — turns the knobs, writes **zero** templates. |
| **Verify** | C | Adds a `values.schema.json` + `helm test` that **rejects bad inputs** before they ship. |

- This is today's whole lesson, socialized: the chart *is* the golden path.

> B self-services on A's blueprint. C makes the blueprint safe to hand out.

<!-- The most on-theme example — it's literally the Helm chart they built today, turned into a shared product. The platform-engineering reveal: the chart author (A) is the platform team, the consumer (B) is the developer, the schema/test (C) is the guardrail. values.schema.json is the underrated star — it's how a platform validates self-service input. -->

---

## A → B → C · The Golden Base Image

| Seat | Student | Does |
| :--- | :--- | :--- |
| **Produce** | A | Builds a hardened base image, pushes to Harbor: `harbor.../base:1.0`. |
| **Consume** | B | Builds their app **`FROM harbor.../base:1.0`** — inherits the blessed toolchain. |
| **Verify** | C | Runs **Trivy** scans + writes a **Kyverno** policy that *blocks* any image not built from the approved base. |

> Supply chain as a team sport: a golden image, everyone downstream of it, a gate that enforces it.

<!-- The security-flavored example, and it uses Harbor, which they already have. This is the supply-chain golden path: approved base + admission policy. C's Kyverno rule is policy-as-code — the platform's "you must come this way." Good for the cybersecurity faculty in the room. -->

---

## Where this goes (name-drop, don't teach)

Same **produce → consume → verify** relay, one level up:

- **Scaffolding catalog** (Backstage software templates) — A writes the "blessed new-service" template; B scaffolds from it in one command; C gates it in CI.
- **Self-service infrastructure** (Crossplane) — A defines a `Database` API; B writes a 5-line claim and *gets* a Postgres; C sets the quota and policy on what can be claimed.

> The seats never change. Only the size of the thing on the conveyor belt.

<!-- Aspirational closer for the relay section — connects back to the Quartermaster's Manifest, where Backstage and Crossplane were named. The point: the produce/consume/verify pattern scales from a Helm chart all the way to a self-service infrastructure API. Don't teach these; just show the pattern is fractal. -->

---

## Instructor Superpower

#### Assign the seats — and the room becomes a platform team

- Pick a scenario, hand out the roles, and the collaboration *is* the curriculum.
- Your students stop being thirty solo operators and start being **one crew on one platform** — produce, consume, verify.
- That is the experience you came here to feel today. It's also the one you can hand your own students next term.

<!-- The destination slide. Agency framing: the instructor's lever is role assignment. They felt it as students today; they can engineer it for their students tomorrow. Land it and stop. -->

---

<!-- _class: lead -->
<!-- _footer: "" -->

# All hands.

```text
   ~~~^~~~~~^~~~~~~^~~~~^~~~~~^~~~
  ~~~~~~^~~~~~~^~~~~^~~~~~~^~~~~~~~
   ~^~~~~~^~~~~~~^~~~~~^~~~~~^~~~~~
```

*One cluster. Many crews. Git keeps the peace.*

<!-- Close here. Short deck, brisk energy. Hand back to the lab or to the Manifest, whichever you ran this alongside. -->
