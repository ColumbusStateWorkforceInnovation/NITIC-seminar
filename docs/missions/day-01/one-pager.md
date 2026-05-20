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
- **09:00 - 10:30** | Lecture: The Wreckage (Linux Basics & Intro to Containers)
- **10:30 - 10:45** | ☕ Break
- **10:45 - 12:00** | Lab: The First Raft (Building your first Container)
- **12:00 - 01:00** | 🥪 Lunch
- **01:00 - 02:30** | Lecture: Into the Deep (Kubernetes Pods)
- **02:30 - 02:45** | ☕ Break
- **02:45 - 04:15** | Lab: Paddling Out (Generators, Namespaces, & The Scavenger Hunt)
- **04:15 - 05:00** | AI Connect: The Socratic Boatswain

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
