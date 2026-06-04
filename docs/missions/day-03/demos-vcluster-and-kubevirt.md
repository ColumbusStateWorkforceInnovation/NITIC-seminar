# 🧪 Podium Cheat-Sheet — Side-Quest Demos: vcluster + KubeVirt

Two ~5-minute "whoa" demos you drive from the **justfile** in front of the room.
Both run against the **remote cluster** (`uss-nitic`). The story each tells:

- 🚣 **the dinghy** (vcluster) — *"a whole Kubernetes cluster, hiding inside one namespace of ours."*
- 🫥 **the stowaway** (KubeVirt) — *"a real virtual machine — its own kernel, its own screen — running as a pod."*

> ⚠️ **Why the VM is tiny CirrOS, not a desktop:** these Azure nodes have **no
> hardware virtualization** (no `/dev/kvm`). KubeVirt falls back to QEMU
> **software emulation**, which is fine for a featherweight VM but would crawl
> on a full GUI. So VNC shows the VM's **graphical console** (its login screen),
> not a clickable desktop. A real desktop needs a KVM-capable node — see the
> note at the bottom.

---

## ✅ Pre-flight (run ONCE, before class — ~4 min)

```bash
just kubevirt-install      # installs KubeVirt (emulation mode) + virtctl + the 'demos' namespace
```

- [ ] `just kubevirt-install` finished with **"KubeVirt ready"** (idempotent — safe to re-run).
- [ ] One warm-up cycle so the container images are cached on the node (makes the live boot fast):
      `just stowaway-up` → `just stowaway-ssh` (login `cirros` / `treasure`, then `exit`) → `just stowaway-down`.
- [ ] `just dinghy-up` once to cache the helm chart, then `just dinghy-down`.
- [ ] macOS: a VNC client is available — `open vnc://…` uses the built-in **Screen Sharing**. (Nothing to install.)

Tear-down is just `just stowaway-down` + `just dinghy-down`. KubeVirt itself can stay installed.

---

## 🚣 Demo 1 — the dinghy (vcluster) · ~5 min

| Beat | Command | Say |
| :--- | :--- | :--- |
| **Launch** | `just dinghy-up` | "I'm creating a brand-new Kubernetes cluster… in about 60 seconds… with one command." |
| **kubectl to it** | `just dinghy-connect` *(leave running)*, then in a 2nd terminal paste the absolute `export KUBECONFIG=…` line it printed, then:<br>`kubectl get ns` / `kubectl get nodes` | "This looks like its own cluster — its own namespaces, its own node, and I'm cluster-admin." |
| **The ah-ha** | `just dinghy-demo` | "Watch — I make a namespace and a deployment *inside* the dinghy… now look at the **host**: the namespace isn't there at all, and the pod is just `…-x-treasure-island-x-dinghy` sitting in **one** namespace. A whole cluster, confined to a namespace." |
| **Scuttle** | `just dinghy-down` | "And it's gone — `helm uninstall`." |

> 💡 `dinghy-demo` is fully scripted (no typing) — good if you want the punchline
> without driving kubectl by hand. `dinghy-connect` is for when you'd rather type
> live on your laptop. They use different ports, so you can run both at once.

**Where it lives on the host:** `kubectl get pods -n vcluster-dinghy` — the
`dinghy-0` StatefulSet pod *is* the cluster's control plane; everything you
create inside shows up here, name-translated.

---

## 🫥 Demo 2 — the stowaway (KubeVirt) · ~5 min

| Beat | Command | Say |
| :--- | :--- | :--- |
| **Boot** | `just stowaway-up` | "I'm booting a real Linux **virtual machine** — and it schedules like any pod." |
| **Show the pod** | `just stowaway-status` | "See `virt-launcher-stowaway-…`? That pod *is* QEMU running the VM." |
| **SSH in** | `just stowaway-ssh`  *(password: `treasure`)*<br>then `uname -a`, `cat /etc/os-release` | "I'll SSH straight into it through a port-forward — its own kernel, its own OS. This is not a container." |
| **Its screen (VNC)** | `just stowaway-vnc` | "And here's its actual **screen** — the graphical console — over VNC, tunneled out of the cluster." |
| **Overboard** | `just stowaway-down` | "Delete the VM like any other object." |

Login: **`cirros` / `treasure`** (set by cloud-init in the VM manifest).

---

## 🧯 If something misbehaves

| Symptom | Fix |
| :--- | :--- |
| `dinghy-demo` → `connection refused` on :18443 | The vcluster API wasn't ready yet. Wait ~20s after `dinghy-up`, re-run. |
| `stowaway-ssh` → `banner exchange` timeout | VM still booting under emulation. Wait ~30s, re-run (first boot is ~60–90s). |
| `stowaway-vnc` → viewer doesn't open | Run `open vnc://localhost:5901` yourself; keep the recipe's terminal open (it holds the tunnel). |
| VM stuck `Scheduling` / "no /dev/kvm" | `useEmulation` didn't apply: re-run `just kubevirt-install`, confirm `kubectl -n kubevirt get kv kubevirt -o jsonpath='{.status.phase}'` = `Deployed`. |
| Port "already in use" | A previous tunnel is still up. The recipes now clear stale forwarders on start; otherwise close the old terminal. |

---

## 📁 What's on disk

- `k8s/demos/dinghy-values.yaml` — vcluster helm values (annotated).
- `k8s/demos/kubevirt-cr.yaml` — KubeVirt config with `useEmulation: true`.
- `k8s/demos/stowaway-vm.yaml` — the CirrOS `VirtualMachine` (cloud-init sets the password).
- Recipes: `just --list | grep -E 'dinghy|stowaway|kubevirt'`.

> 🖥️ **Want a real clickable desktop later?** It needs a **KVM-capable node**
> (bare metal, or a cloud VM size with nested virtualization). On such a node,
> drop `useEmulation`, swap the containerDisk for a Fedora/Ubuntu cloud image,
> and add a cloud-init that installs a lightweight desktop + a VNC server — then
> `just stowaway-vnc` lands you on a GUI instead of a console.
