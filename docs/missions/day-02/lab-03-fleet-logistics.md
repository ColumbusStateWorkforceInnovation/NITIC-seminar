# Lab 03: Fleet Logistics (3-Tier Architecture)

No ship sails alone. It's time to meet **Kubernetes Services** and establish communication across the fleet.

In this capstone activity, you will form a 3-person alliance. Together, you will wire a 3-tier application across three completely distinct namespaces.

The container images are pre-built and handed to you — your mission is the **plumbing**: writing each tier's `Deployment` and `Service`, and pointing one tier at the next using the correct internal DNS name. Here's the catch that makes this realistic: a *wrong* DNS name doesn't crash anything. The pod starts up green and happy; the link just silently goes dead. Part of your mission is learning to **prove** a connection works instead of assuming it does.

## 🤖 The AI Code Reviewer

Before we begin, we need to upgrade our AI. We don't just want the Boatswain to give hints; we want it to aggressively review our YAML before we deploy it.

Open your `AGENTS.md` file and append this new rule:

> **RULE 2: THE SYLLABUS ENFORCER**
> When reviewing Kubernetes YAML, NEVER tell me if it works or not. Instead, violently critique my YAML based on this strict class rule: 
> 1. Did I use a hardcoded IP address? If so, demand I use a Service. Explain why hardcoded IPs sink ships.

## Step 1: Form Your Alliance

Group up into teams of 3. Decide who will take which role:
* **Student A: The Storehouse (Database)** - You will deploy a Redis cache.
* **Student B: The Ledger (Backend API)** - You will deploy a Go API (`podinfo`) and point it at the Storehouse.
* **Student C: The Radar (Frontend UI)** - You will deploy a web UI and point it at the Ledger.

*Make sure you know exactly what your teammates' namespaces are!*

## Step 2: Deploying the Tiers

*Important: Do not use raw Pods. You must write a `Deployment` and a `Service` for your tier.*

### Student A (The Storehouse)
1. Write a Deployment using the `redis:alpine` image. Expose port `6379`.
2. Generate a Service of type `ClusterIP` pointing to your Deployment.
3. Feed your YAML to `aichat` and ask the Code Reviewer for a critique.
4. Apply your manifests.

### Student B (The Ledger)
1. Write a Deployment using the `stefanprodan/podinfo` image.
2. **The Connection:** You must inject an environment variable named `CACHE_URL`. Its value must be the internal DNS name of Student A's Redis service. 
   *(Format: `tcp://<service-name>.<student-a-namespace>.svc.cluster.local:6379`)*
3. Generate a Service of type `ClusterIP` for your Backend.
4. Apply your manifests. **Heads up:** a wrong namespace here will *not* crash your pod — `podinfo` boots up perfectly fine whether or not it can reach Redis. The broken link is completely silent, which is exactly why you must test it yourself.
5. **Prove the link.** Shell into your `podinfo` pod (in `k9s`, highlight it and press `s`) and run:
   - `nslookup <service-name>.<student-a-namespace>.svc.cluster.local` — does the name resolve?
   - `nc -z -v <service-name>.<student-a-namespace>.svc.cluster.local 6379` — "succeeded" means Redis is reachable.
   A failure here while your pod still shows green is the silent break in action — hunt down the typo.

### Student C (The Radar)
1. Write a Deployment using the `paulbouwer/hello-kubernetes` image.
2. **The Connection:** You must inject an environment variable named `BACKEND_URL`. Its value must be the internal DNS name of Student B's Service.
3. Generate a Service. Since you are the UI, make your Service type `NodePort` or use a Gateway HTTPRoute so you can see it in your browser!
4. Apply your manifests, then **prove the link**: shell into your frontend pod and run
   `wget -qO- http://<service-name>.<student-b-namespace>.svc.cluster.local:<port>/version`.
   A JSON reply means the Ledger is reachable. Then open your NodePort/Gateway URL in a browser to confirm the page loads.

## 🌪️ THE TWIST: The Network Blockade!

*(Once all teams have their 3-tier app working and cheering...)*

**INSTRUCTOR ACTION:** The Instructor will execute the `Network Blockade` script.

Suddenly, everyone's UI will break. The Backend can no longer talk to the Storehouse. The Radar can no longer talk to the Ledger. The cluster has been hit by a **NetworkPolicy Blockade**. The Admiral has locked down all cross-namespace communication for security reasons!

**Your Stretch Goal Mission:**
You cannot delete the Admiral's blockade. You must adapt to it. Remember: NetworkPolicies are *additive* — you don't remove the blockade, you add allow-rules alongside it. Each tier only needs to open the door to the tier that calls it.
1. Open `aichat` and ask the Boatswain: *"What is a Kubernetes NetworkPolicy, and how do I write one to allow ingress traffic from a specific namespace?"*
2. **Student A** must write a NetworkPolicy allowing ingress from Student B's namespace (so the Ledger can reach the Storehouse).
3. **Student B** must write a NetworkPolicy allowing ingress from Student C's namespace (so the Radar can reach the Ledger).
4. **Student C** must write a NetworkPolicy too — but here's the catch: your visitors are *web browsers*, not a namespace! You can't select the browser with a `namespaceSelector`. Instead, write a policy on your `radar` pod that allows ingress to your **web port** (e.g. `8080`) from *any* source (an `ingress` rule with `ports` but no `from`). Without this, the blockade keeps your UI dark even after A and B fix their tiers.
5. Be the first alliance to pierce the blockade and restore your 3-tier app — all the way to a working page in the browser!

*(Hint for Student C: traffic arriving via a NodePort or Gateway is rewritten to look like it comes from the cluster node, not from your teammate's namespace — which is exactly why the `namespaceSelector` trick that saves Students A and B won't help you. Open the port itself.)*
