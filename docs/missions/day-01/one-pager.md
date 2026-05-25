# Day 1: The Ship Has Sunk

```text
       _~
    _~ )_)_~
    )_))_))_)
    _!__!__!_
    \______t/
  ~~~~~~~~~~~~~
```
*Welcome to the island. Earning survival skills and exploring the raw elements of the new world.*

## 🕘 The Schedule
- **09:00 - 09:15** | Welcome & Storytime
- **09:15 - 10:30** | Lab 00: Building Your Vessel (Create the Ubuntu VM)
- **10:30 - 10:45** | ☕ Break
- **10:45 - 12:00** | Lab 00, cont.: Bootstrap & Verify (`setup-client.sh`)
- **12:00 - 01:00** | 🥪 Lunch
- **01:00 - 01:45** | Lecture: The Wreckage (Linux Basics & Intro to Containers)
- **01:45 - 03:00** | Lab 01: The First Raft (Building your first Container)
- **03:00 - 03:15** | ☕ Break
- **03:15 - 04:00** | Lecture: Into the Deep (Kubernetes Pods)
- **04:00 - 05:00** | Lab 02: Paddling Out (Generators, Diagnostics & The Scavenger Hunt)

---

## ⚓ The Boatswain's Cheat Sheet

### Containers (Docker)
* **Build an Image:** `docker build -t <image-name> .`
* **Run a Container:** `docker run -d -p 8080:80 <image-name>`
* **List Running Containers:** `docker ps`
* **Push to Registry:** `docker push <registry>/<image-name>`

### Kubernetes (The Orchestrator)
* **Claim Your Land (Namespace):** `kubectl create namespace <your-name>`
* **Set Default Context:** `kubectl config set-context --current --namespace=<your-name>`
* **Generate a Pod YAML:** `kubectl run my-pod --image=nginx --dry-run=client -o yaml > pod.yaml`
* **Apply YAML:** `kubectl apply -f pod.yaml`
* **Check Status:** `kubectl get pods`
* **View Logs:** `kubectl logs my-pod`
* **Board the Pod (Exec):** `kubectl exec -it my-pod -- /bin/sh`

---

## 📝 Captain's Log (Notes)

*(Jot down your survival strategies here...)*

<br><br><br><br><br><br><br><br><br><br>
