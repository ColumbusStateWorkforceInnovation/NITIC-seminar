# Lab 02: Paddling Out (Diagnostics)

Your raft is built and safely stored in the Harbor. Now, it's time to paddle out into the ocean (the Kubernetes Cluster).

A raw container is just a box. Kubernetes wraps that box in a life-jacket called a **Pod**. In this lab, you will generate a Pod manifest, claim your territory, and learn how to patch leaks when things go wrong.

## ⚓ First: Board the Cluster

Up to now everything ran on your own VM. Lab 02 is the first time you steer the **live island cluster** — and for that, `kubectl` needs a **kubeconfig**: your chart and key to the ocean.

1. In Firefox, open **Rancher** at `https://rancher.{{ lab_domain }}` and log in with the account your instructor issued you.
2. Open the lab cluster and click **Copy KubeConfig to Clipboard** (top-right of the cluster view).
3. Back in your terminal, create the config folder: `mkdir -p ~/.kube`. Then open the file in your VS Code workspace (`code ~/.kube/config` — or just **File → Open File…** in your already-open VS Code window). Paste the kubeconfig, save with **Ctrl-S**, and close the tab.
4. Confirm you can reach the ocean: `kubectl get ns`. A list of namespaces means you're connected — if it errors, flag your instructor before going on.

## Step 1: Claiming Your Territory

The ocean is massive and shared by 30 other pirates. If you just throw your raft in, it will get lost. You need an isolated patch of water called a `Namespace`.

The Admiral provisioned your namespace for you ahead of time — it's named `student-<your-name>` (as printed on your crew credentials card). Verify and claim it:

1. Confirm it's yours: `kubectl get pods -n student-<your-name>` (you should see no pods yet — that's fine; you haven't deployed anything).
2. Tell `kubectl` to always operate in your patch of water so you don't have to keep typing `-n student-<your-name>`:
   `kubectl config set-context --current --namespace=student-<your-name>`

## Step 2: Generating the Manifest (No Raw YAML!)

*Pedagogical Note: No one memorizes Kubernetes YAML. We generate it.*

Instead of looking up the exact YAML syntax for a Pod, we will ask Kubernetes to generate it for us using a "dry run".

1. Run the generator command:
   `kubectl run my-raft --image=harbor.{{ lab_domain }}/raft-fleet/<your-name>:v1 --dry-run=client -o yaml > pod.yaml`
2. Open `pod.yaml` in VS Code (it appears in your `~/lab` workspace from Lab 01 — click it in the explorer panel). You will see a perfectly formatted declarative definition of your raft!
3. Apply it to the ocean:
   `kubectl apply -f pod.yaml`
4. Check if it's floating:
   `kubectl get pods`

## Step 3: The Ghost Ship (Immutability Demo)

Let's prove why we use Dockerfiles. 

1. Exec (SSH) directly into your running pod:
   `kubectl exec -it my-raft -- /bin/sh`
2. You are now inside the container. Let's make a manual edit to your flag:
   `echo "<h1>I WAS MANUALLY HACKED</h1>" > /usr/share/nginx/html/index.html`
3. Exit the container (`exit`), then read the page back **through Kubernetes** to confirm your sabotage landed:
   `kubectl exec my-raft -- cat /usr/share/nginx/html/index.html`
   You'll see the `I WAS MANUALLY HACKED` message.
   !!! info "Why not just `curl` the pod's IP?"
       A Pod's IP (something like `10.42.x.x`) lives on the cluster's *internal* network — it isn't routable from your VM. `kubectl exec` reaches inside the pod for you, which is why we read the file that way.
4. Now, the storm hits. Delete the pod:
   `kubectl delete pod my-raft`
5. The ocean is empty. Apply your `pod.yaml` again:
   `kubectl apply -f pod.yaml`
6. Read the page one more time: `kubectl exec my-raft -- cat /usr/share/nginx/html/index.html`. The hacked message is **gone** — your original flag is back! The pod pulled the immutable image from the Harbor. **Lesson learned: Manual server configurations die. Infrastructure as Code survives.**

## Step 4: The Scavenger Hunt

Somewhere out in the cluster, Admiral Bash has hidden a `treasure-chest` Pod in a random, secret namespace. That pod is continuously writing a secret, 6-character code to its standard output (logs).

**Your Mission:**

1. Find the pod. (Hint: `kubectl get pods -A` lists pods across *all* namespaces).
2. Read the logs of that pod to extract the secret code.
3. Share the code with the room.
