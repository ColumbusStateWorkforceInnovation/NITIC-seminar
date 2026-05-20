# Lab 03: Fleet Logistics (3-Tier Architecture)

No ship sails alone. It's time to meet **Linky** (Kubernetes Services) and establish communication across the fleet.

In this capstone activity, you will form a 3-person alliance. Together, you will deploy a functional 3-tier application ecosystem across three completely distinct namespaces. 

## 🤖 The AI Code Reviewer

Before we begin, we need to upgrade our AI. We don't just want the Boatswain to give hints; we want it to aggressively review our YAML before we deploy it.

Open your `AGENTS.md` file and append this new rule:

> **RULE 2: THE SYLLABUS ENFORCER**
> When reviewing Kubernetes YAML, NEVER tell me if it works or not. Instead, violently critique my YAML based on this strict class rule: 
> 1. Did I use a hardcoded IP address? If so, demand I use a Service. Explain why hardcoded IPs sink ships.

## Step 1: Form Your Alliance

Group up into teams of 3. Decide who will take which role:
* **Student A: The Storehouse (Database)** - You will deploy a Redis cache.
* **Student B: The Ledger (Backend API)** - You will deploy a Go API that reads/writes to the Storehouse.
* **Student C: The Radar (Frontend UI)** - You will deploy a React Web UI that displays data from the Ledger.

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
4. Apply your manifests. If you got Student A's namespace wrong, your pod will crash!

### Student C (The Radar)
1. Write a Deployment using the `paulbouwer/hello-kubernetes` image.
2. **The Connection:** You must inject an environment variable named `BACKEND_URL`. Its value must be the internal DNS name of Student B's Service.
3. Generate a Service. Since you are the UI, make your Service type `NodePort` or use a Gateway HTTPRoute so you can see it in your browser!
4. Apply your manifests.

## 🌪️ THE TWIST: The Network Blockade!

*(Once all teams have their 3-tier app working and cheering...)*

**INSTRUCTOR ACTION:** The Instructor will execute the `Network Blockade` script.

Suddenly, everyone's UI will break. The Backend can no longer talk to the Storehouse. The Radar can no longer talk to the Ledger. The cluster has been hit by a **NetworkPolicy Blockade**. The Admiral has locked down all cross-namespace communication for security reasons!

**Your Stretch Goal Mission:**
You cannot delete the Admiral's blockade. You must adapt to it.
1. Open `aichat` and ask the Boatswain: *"What is a Kubernetes NetworkPolicy, and how do I write one to allow ingress traffic from a specific namespace?"*
2. Student A must write a NetworkPolicy allowing traffic from Student B's namespace.
3. Student B must write a NetworkPolicy allowing traffic from Student C's namespace.
4. The first alliance to pierce the blockade and restore their 3-tier app wins the final prize!
