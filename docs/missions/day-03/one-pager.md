# Day 3: Automated Shipyards

```text
      []_____
     /  HAZEL \____
    /___________  \
    |   []   [] |==|
    |___________|==|   "Build once. Stamp the fleet."
   ~~~~~~~~~~~~~~~~~~~
```
*From hand-built rafts to mass production. Today you draft blueprints with Hazel (Helm) and hand the wheel to the Automated Shipyards (GitOps).*

## 🕘 The Schedule
- **09:00 - 10:30** | Lecture: The Problem with Raw YAML (Helm & Templating)
- **10:30 - 10:45** | ☕ Break
- **10:45 - 12:00** | Lab: Drafting the Blueprint (Build a Helm Chart)
- **12:00 - 01:00** | 🥪 Lunch
- **01:00 - 02:30** | Lecture: Git Is Truth (GitOps with Gitea & ArgoCD)
- **02:30 - 02:45** | ☕ Break
- **02:45 - 04:15** | Lab & Demo: The Automated Shipyard & Wiring the Archipelago
- **04:15 - 05:00** | AI Connect: The Shipyard & The Logbook

---

## ⚓ The Shipwright's Cheat Sheet

### Helm (Hazel, the Shipwright)
* **Scaffold a Chart:** `helm create <chart-name>`
* **Render Without Installing:** `helm template ./<chart-name>`
* **Install a Release:** `helm install <release> ./<chart-name> -n <namespace>`
* **Upgrade a Release:** `helm upgrade <release> ./<chart-name> -n <namespace>`
* **Override a Value Live:** `helm upgrade <release> ./<chart-name> --set key=value`
* **List Releases:** `helm list -n <namespace>`
* **Scrap a Release:** `helm uninstall <release> -n <namespace>`

### GitOps (The Automated Shipyard)
* **Trunk Branch:** `maindeck` (not `main`)
* **Init & Push:** `git init -b maindeck` → `git add .` → `git commit` → `git push`
* **Gitea (Captain's Log):** `gitea.{{ lab_domain }}`
* **ArgoCD (The Shipyard):** `argocd.{{ lab_domain }}`
* **Harbor (The Registry):** `harbor.{{ lab_domain }}`

### The One Commandment
> **Git is Truth.** The repo is the *desired state* (Captain's Log). The
> cluster is the *live state* (Crew's Actions). ArgoCD makes the second match
> the first — never edit the cluster directly.

---

## 📝 Captain's Log (Notes)

*(Sketch your chart structure and your ArgoCD wiring here...)*

<br><br><br><br><br><br><br><br>
