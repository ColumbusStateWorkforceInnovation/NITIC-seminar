# Welcome Aboard, Admiral!

```text
       _~
    _~ )_)_~
    )_))_))_)
    _!__!__!_
    \______t/
  ~~~~~~~~~~~~~
```

You've washed ashore on **Admiral Bash's Island Adventure** — a 4-day cloud-native intensive built for educators who want to bring real DevOps tooling back into their own classrooms.

The mainframe is sunk. The rafts are being lashed together. Over the next four days you'll meet the crew, draft your first blueprints, and survive a pirate raid — and along the way, you'll pick up a set of **Instructor Superpowers** for running modern Kubernetes-based labs without losing your weekends to environment cleanup.

## 🗺️ Where to Sail Next

- **[Course Agenda](course-agenda.md)** — the 4-day at-a-glance schedule.
- **[The Syllabus](stakeholder-updates/2026-04-22-curriculum-deep-dive.md)** — the deeper "why" behind each day.
- **Missions** — the actual mission docs for each day live in the sidebar:
  - **Day 1 — The Ship Has Sunk** (Linux, Containers, Pods)
  - **Day 2 — Meet the Crew** (Deployments, Services, the 3-tier alliance)
  - **Day 3 — Automated Shipyards** (Helm, GitOps, Network-as-Code)
  - **Day 4 — The Admiral's Challenge** (vCluster, KubeVirt, Chaos)
- **[Book Readings (Storytime)](missions/book-readings.md)** — the daily readings from the CNCF *Admiral Bash's Island Adventure* picture book that frame each day.

## ⚓ Your Island Toolbelt

You'll be using these services constantly — they're all served from this same cluster:

| Service | URL |
| :--- | :--- |
| **Rancher** (cluster UI, kubeconfig) | <https://rancher.{{ lab_domain }}> |
| **ArgoCD** (GitOps engine, Day 3+) | <https://argocd.{{ lab_domain }}> |
| **Gitea** (internal Git, Day 3+) | <https://gitea.{{ lab_domain }}> |
| **Harbor** (container registry, Day 1+) | <https://harbor.{{ lab_domain }}> |
| **AI Engine** (Socratic Boatswain) | <https://ai.{{ lab_domain }}/v1> |
| **Flash Poll** (in-class quizzes) | <https://poll.{{ lab_domain }}> |
| **Mailpit** (mock SMTP — catches mail from Gitea, Grafana, Harbor & ArgoCD) | <https://mailpit.{{ lab_domain }}> |
| **Grafana** (logs & metrics) | <https://grafana.{{ lab_domain }}> |

## 🚢 If This Is Your First Boarding

1. Run `setup-client.sh` on your VM (see your credential card).
2. Drop into Fish: `fish`.
3. Verify the toolkit:  `k9s version`, `kubectl version --client`, `aichat`.
4. Open **Day 1 → Briefing** in the sidebar.

You're ready. Hoist the flag — let's set sail. 🏴‍☠️
