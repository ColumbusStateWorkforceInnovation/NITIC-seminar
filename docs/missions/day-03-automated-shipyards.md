# Day 3: Automated Blueprints & Shipping Lanes

**Date**: June 3, 2026
**Theme**: Transitioning from manual steering to mass production and automated shipping with Hazel (Helm), GitOps (ArgoCD), and in-cluster CI (Gitea Actions).

## 🌅 Morning: CI to Image, then Meet Hazel

Day 3 opens with the **build half** of CI/CD — the 30-min Gitea Actions demo that closes the gap between "code edit" and "image in the registry." Then Hazel (Helm) takes the floor to template what we just learned to build.

### Key Objectives

- See a complete `git push → image in Harbor` loop running entirely inside the lab cluster.
- Understand that **Gitea Actions** is byte-for-byte GitHub Actions YAML — the same workflow file runs on github.com unchanged.
- Hear the names **Argo Workflows** and **Tekton** for when the room outgrows Gitea Actions.
- Understand the value of templating with Helm.
- Package existing manifests into a reusable format.
- Replace manual `kubectl apply` with Helm deployments.


### Activities & Missions

1. **Gitea Actions (30-min opening demo)**
   - (Reference: [`demo-gitea-actions.md`](day-03/demo-gitea-actions.md), slides at [`slides/day-03/gitea-actions.md`](../../slides/day-03/gitea-actions.md), example workflow at [`gitea-actions-demo/.gitea/workflows/ci.yaml`](day-03/gitea-actions-demo/.gitea/workflows/ci.yaml).)
   - Instructor pushes a one-character change to a Gitea repo; the room watches the **act_runner** pod pick up the workflow, build the image, and push a new tag to Harbor — under 60 seconds. ArgoCD picks up this image in the afternoon as a callback.
   - **🧑‍🏫 Instructor Superpower (One YAML, Two Homes)**: the same `.gitea/workflows/ci.yaml` that ran in our cluster runs unchanged on `github.com` under `.github/workflows/`. Teach the syntax once; it ports.
   - **Sidebar slides** for Argo Workflows and Tekton are part of the deck — name them, don't demo them. The decision matrix lives on slide 11.
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
   - **🧑‍🏫 Instructor Superpower (The Live Classroom Demo)**: Deliver the "JupyterLab GitOps" demo! Have the instructor (or a brave student) commit a Helm chart containing a **JupyterLab** deployment to the local Gitea instance. ArgoCD spots it and deploys the data science environment. The "Aha!" Moment: Prove to instructors that by adding `pandas` to a `requirements.txt` and pushing to Git, ArgoCD instantly sinks the new Python library to every student's Jupyter environment without them ever having to type `pip install` locally! You just distributed a heavy data science lab via a URL.

## 🪢 Late Afternoon Callback: Close the Loop

Around 16:00, after the ArgoCD lab, run a 2-minute callback to the morning's Gitea Actions demo: *"Remember the tag we pushed to Harbor at 09:15? Watch."* ArgoCD syncs, the image rolls out, the live URL shows the morning's edit. That's the moment students see the full `git push → live app` story land in their cluster.

## 🌉 Late Afternoon: Wiring the Archipelago (Network as Code)

While deploying apps via GitOps is great, true production environments need deep-sea networking. Standard web pods aren't rugged enough for routing.

### Key Objectives

- Use Custom Resource Definitions (CRDs) to deploy heavy network structures natively inside Kubernetes.
- Prove that "Network as Code" works the exact same way as "App as Code".

### Activities & Missions

1. **The Ghost Fleet Appears (Clabernetes)**
   - **Mission**: Have ArgoCD deploy a full-blown commercial router topology so the islands can communicate on a lower level.
   - Using GitOps, we inject a Clabernetes `Topology` manifest instead of a standard `Deployment`. This manifest summons two distinct Cisco or Nokia router nodes (`router-port` and `router-starboard`).
2. **Establishing the Trade Route**
   - Students leverage `kubectl exec` to bypass standard K8s shells and drop directly into the commercial router's interactive CLI (e.g., Nokia SR Linux).
   - They configure a basic static route or BGP peering between the two islands. When `router-port` can `ping` the loopback IP of `router-starboard`, the deep-sea cable is active!
   - **🧑‍🏫 Instructor Superpower (Replacing the Hardware Lab)**: This is arguably the heaviest anchor we can drop on traditional IT networking education. Teaching BGP, OSPF, and EVPN historically requires massive VM overhead (GNS3, EVE-NG) or expensive proprietary physical hardware labs. With Clabernetes + ArgoCD, a faculty member can provision a complete, isolated multi-router lab for every single student just by applying a few lines of K8s YAML! No heavy VMs; just pure Containerlab power scaled via Kubernetes GitOps.

---

### 🤖 Curiosity Side-Quest: The Shipyard & The Logbook
_Evolving the Socratic Boatswain `AGENTS.md` context for automation._

- **Mission**: GitOps relies entirely on a mental model: "Git is Truth." Let's force the AI to ensure students understand this before it helps them.
- Append `Rule Update 3` to `~/lab/AGENTS.md`, then `.exit` and re-run `hail` so the new rule loads:
  > *"1. If I ask about Helm Go-Template syntax (like `{{ range }}`), DO NOT write the loop. Refer to loops as the 'Ship's Ledger' and ask me what list from my `values.yaml` I am iterating over first. 2. If I complain that my ArgoCD application is 'OutOfSync' or 'Degraded', refuse to help! Demand that I explain to you the difference between the 'Captain's Log' (Desired State perfectly stored in Git) and the 'Crew's Actions' (Live State in the cluster). Only after I explain the difference can you give an Argo UI hint."*
- Try manually deleting a Pod using `kubectl` against your ArgoCD deployment and ask the AI why it came back!
