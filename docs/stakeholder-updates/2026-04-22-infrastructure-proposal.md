# 📝 Stakeholder Update: Infrastructure Hardware Assessment
**Date:** 2026-04-22
**Focus:** Cloud Compute Capabilities & Cost Estimation for "Admiral Bash's Island Adventure"

## ⚓ Status Summary
To provide up to 30 visiting faculty members with a world-class, cloud-native pedagogical experience, we have finalized the architecture to run atop **One Giant Shared Kubernetes Cluster**. This eliminates brittle local VM installations on student laptops, ensuring smooth onboarding and allowing us to demonstrate true "Instructor Superpowers" centrally.

---

## 🖥️ Workload Assumptions & Requirements

Hosting a full DevOps class centrally is demanding. The compute environment must sustain massive concurrent bursts (e.g., 30 students hitting "Apply" at the exact same second). Here is the payload breakdown:

### 1. The Core Infrastructure Tax (Standard Demand)
- **K3s Overhead & CI/CD**: Running the Kubernetes control plane, Harbor (localized Docker registry for fast pulling), Gitea (internal version control), and ArgoCD.
- *Requirement*: ~8 vCPUs / 16GB RAM

### 2. The Student Pods (High Demand)
- **Live Environments**: 30 isolated namespaces. Each will concurrently run microservices (Web pods, Redis databases, etc.) and establish dynamic routes.
- **Clabernetes Network Emulation**: 30 virtual Cisco/Nokia routers emulated locally.
- *Requirement*: ~16 vCPUs / 32GB RAM

### 3. The Generative AI TA (Extreme GPU Demand)
- **Local LLM (Gemma 4 / 7B)**: We are hosting our own LLM inside the cluster to avoid API costs and demonstrate AI-at-Scale.
- **Concurrency**: Typical 7B inference uses ~8GB VRAM per user. To support a burst of 30 simultaneous queries without crashing the model down to slow CPU-offload speeds, we need a massive VRAM buffer and tensor-batching capabilities.
- *Requirement*: 1x Data Center GPU (Minimum 24GB VRAM, ideally 80GB VRAM).

### **Target Recommendation:** Minimum 24 vCPUs, 128GB RAM, and 1x 24GB+ GPU.

---

## ☁️ Azure Instance Assessment: `Standard_NC24ads_A100_v4`

The proposed Azure `NC24ads_A100_v4` is an absolute titan and perfectly aligns with our curriculum needs:
- **CPU:** 24 vCPUs (AMD EPYC)
- **RAM:** 220 GiB
- **GPU:** 1x NVIDIA A100 (80GB VRAM)

**Verdict:** This machine will easily crush the curriculum requirements. The 80GB of VRAM guarantees that all 30 students can interrogate their AI Assistant simultaneously with zero lag, while the 220GB of RAM provides an indestructible safety buffer against students writing memory dumps or infinite loops during the Chaos Mesh labs.

---

## 💸 Cost Estimation (80 Hour Block)
*Assumes 24 hours of live teaching (4 days x 6 hours) + 56 hours of pre-seminar dry-running and testing.*

| Pricing Tier | Est. Hourly Rate | Total Cost (80 Hours) | Risk Profile |
| :--- | :--- | :--- | :--- |
| **Pay-As-You-Go** | ~$4.00 / hr | **~$320.00** | Zero Risk. Guaranteed uptime during seminar. |
| **Azure Spot Instance** | ~$1.00 / hr | **~$80.00** | High Risk. Azure can randomly reboot/evict the VM if server demand spikes elsewhere. |

### Procurement Recommendation
For ~$320, we can provide 30 faculty members an enterprise-grade Kubernetes experience powered by an A100 GPU without the headache of managing local hypervisors. We **recommend** budgeting $350 for On-Demand pricing to ensure zero disruption during the live May 20th seminar.
