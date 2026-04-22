# 📋 Purser's Todo Ledger

**Goal:** 100% Preparedness for "Admiral Bash's Island Adventure" DevOps Intensive by **May 20th**.

## 📊 Status Summary
- **Current Phase:** Infrastructure Engineering & Mission Development

## 🗓️ Methodology
This ledger tracks major milestones across four primary domains to ensure overall readiness by the target date. 

---

### 📚 Curriculum & Content
- [x] Establish high-level narrative and 4-day course outline.
- [x] Draft initial daily mission concepts.
- [x] Align daily objectives with core WIIT syllabus topics.
- [ ] Deploy an in-cluster documentation platform (e.g., MkDocs or Educates.dev) to serve mission docs dynamically.
- [ ] Develop and finalize student handouts and reference materials.
- [ ] Finalize instructor slide decks.

### 💻 Lab Infrastructure
- [x] Confirm the lab environment architecture: **One Giant Shared k3d Cluster**.
- [ ] Develop backend manifests and Helms charts to bootstrap the core cluster capabilities:
  - [ ] Internal Registry (Harbor)
  - [ ] GitOps Engine (ArgoCD) & Version Control (Gitea)
  - [ ] Networking Topologies (Clabernetes & Containerlab)
  - [ ] Instructor Demonstration Tools (vCluster & KubeVirt - Single Instance)
  - [ ] Incident Engine (Chaos Mesh)
  - [ ] Local AI Inference Engine (Ollama/vLLM hosting Gemma4)
- [ ] Write `setup-client.sh` bootstrap script. Must identically provision the student terminal with **Fish**, inject standard aliases (`k=kubectl`), and install/configure `aichat` to point to the cluster's internal Gemma4 endpoint.
- [x] Finalize student workstation network access requirements with CSCC IT (Standard SSH/CLI access to the shared cluster; NO Kasm/Guacamole required).
- [ ] Perform end-to-end testing of daily lab exercises in the finalized environment.

### 🎁 Logistics & Platform
- [ ] Procure door prizes (Hold on ordering book copies for now).
- [ ] Outline badging requirements (Credly).
- [ ] Set up and configure the Engagez platform.

### 👩‍🏫 Instructor Prep
- [ ] Conduct comprehensive dry-run of the 4-day curriculum.
- [ ] Address any gaps identified during the dry-run.
