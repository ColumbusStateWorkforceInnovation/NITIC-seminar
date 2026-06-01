# Day 2: Meet the Crew

```text
       ___
     _/_|_\_
    |  o o  |  "I orchestrate the fleet."
    |__\_/__|     - Captain Kube
      |   |
```
*Expanding our view. Meeting Captain Kube, organizing the cluster, and connecting our fleet with internal Services.*

## 🕘 The Schedule
- **09:00 - 09:10** | 📖 Storytime: Meet Captain Kube
- **09:10 - 09:20** | Demo: Kustomize (the operator's tool)
- **09:20 - 10:30** | Lecture: The Radar Room (K8s Architecture, Deployments, & ConfigMaps)
- **10:30 - 10:45** | ☕ Break
- **10:45 - 12:00** | Lab: The Radar Room & Deploying the Fleet (k9s intro)
- **12:00 - 01:00** | 🥪 Lunch
- **01:00 - 02:30** | Lecture: Drawing the Fleet (Networking & Services)
- **02:30 - 02:45** | ☕ Break
- **02:45 - 04:15** | Lab: Fleet Logistics (The 3-Tier Group Activity)
- **04:15 - 05:00** | AI Connect: The Code Reviewer

---

## ⚓ The Radar Room Cheat Sheet

### `k9s` Keyboard Shortcuts
* **Start k9s:** `k9s` (or `k9s -n <your-namespace>`)
* **Change Namespace:** Type `0` for all namespaces, or type `:` then `ns` and hit enter to select yours.
* **Search / Filter:** Type `/` and type the name of the resource you are looking for.
* **View Logs:** Highlight a pod and press `l` (lowercase L). Press `Esc` to go back.
* **Get a Shell (Exec):** Highlight a pod and press `s`. Type `exit` to leave.
* **Describe Resource:** Highlight a resource and press `d`.
* **Delete Resource:** Highlight a resource and press `Ctrl-d`.

### Declarative Deployments
* **Generate Deployment YAML:** `kubectl create deployment my-ship --image=nginx --dry-run=client -o yaml > deploy.yaml`
* **Scale Deployment:** `kubectl scale deployment my-ship --replicas=3`

### Internal Networking (Services)
* **Generate Service YAML:** `kubectl expose deployment my-ship --port=80 --target-port=8080 --type=ClusterIP --dry-run=client -o yaml > svc.yaml`
* **Internal DNS Format:** `http://<service-name>.<namespace>.svc.cluster.local:<port>`

---

## 📝 Captain's Log (Notes)

*(Jot down your survival strategies here...)*

<br><br><br><br><br><br><br><br>
