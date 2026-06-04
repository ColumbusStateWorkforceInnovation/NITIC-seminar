# Demo: vcluster + KubeVirt (clusters & VMs as pods)

> **Slot:** Day 3 side-quest — two ~5-minute instructor-led demos
> **Audience:** mixed students + faculty
> **Mode:** instructor at the keyboard, driven entirely from the `justfile`
> **Cheat-sheet:** [Podium run-of-show](demos-vcluster-and-kubevirt.md)

Two quick "wait, *what?*" demos that stretch the mental model of what a pod can
be. By Day 3 the room is comfortable that a pod runs **a container**. These two
demos show a pod can also run **a whole Kubernetes cluster** and **a whole
virtual machine** — same scheduler, same `kubectl`, same cluster.

- 🚣 **the dinghy** — a [vcluster](https://www.vcluster.com/): a fully working
  Kubernetes "cluster" that is really just a StatefulSet of pods inside **one
  namespace** of ours.
- 🫥 **the stowaway** — a [KubeVirt](https://kubevirt.io/) virtual machine: a
  real Linux VM (its own kernel, its own screen) running **inside a pod**.

!!! warning "Why the VM is a tiny console, not a desktop"
    These lab nodes have **no hardware virtualization** (`/dev/kvm` is absent),
    so KubeVirt runs in QEMU **software-emulation** mode. That's fine for a
    featherweight VM but far too slow for a graphical desktop. So the VM is
    **CirrOS**, and the VNC view shows its **graphical console** (the login
    screen) — proof it's a real machine — rather than a clickable desktop. A
    full desktop would need a KVM-capable node.

---

## 🚣 Demo 1 — the dinghy (vcluster)

A whole cluster, carried aboard the big one.

```bash
just dinghy-up        # creates a vcluster in ~60 seconds
just dinghy-connect   # writes a kubeconfig + opens a tunnel — LEAVE THIS RUNNING

# …then, in ANOTHER terminal, paste the absolute `export KUBECONFIG=…` line that
# dinghy-connect printed (it resolves the full path so it works from anywhere):
export KUBECONFIG=/path/to/NITIC-seminar/.kube/dinghy.kconfig
kubectl get ns        # looks like a brand-new, empty cluster
kubectl get nodes     # its own (synced) node — and you're cluster-admin
```

**The ah-ha** — run the scripted version and watch the punchline:

```bash
just dinghy-demo
```

It creates a namespace (`treasure-island`) and a deployment (`grog`) **inside**
the dinghy — then looks at the **host** cluster, where:

- the `treasure-island` namespace **doesn't exist** (it's virtual), and
- the pod shows up name-translated as `grog-…-x-treasure-island-x-dinghy`,
  sitting in the single `vcluster-dinghy` namespace.

> **One sentence to land it:** *"A complete cluster — its own namespaces,
> nodes, and workloads — lived inside one namespace of ours, isolated from
> everything else."*

Tidy up:

```bash
just dinghy-down      # helm uninstall + drop the namespace
```

**Where it really lives:** `kubectl get pods -n vcluster-dinghy` — the
`dinghy-0` pod *is* the virtual control plane.

---

## 🫥 Demo 2 — the stowaway (KubeVirt)

A real virtual machine, smuggled aboard inside a pod.

!!! note "One-time prep (before class, ~4 min)"
    ```bash
    just kubevirt-install   # installs KubeVirt (emulation mode) + virtctl + the 'demos' namespace
    ```
    Idempotent — safe to re-run. Do a warm-up `stowaway-up`/`stowaway-down`
    cycle once so the VM image is cached and the live boot is fast.

```bash
just stowaway-up        # boots a CirrOS VM (~60–90s to a login)
just stowaway-status    # see the virt-launcher-stowaway-… POD — that's QEMU running the VM
just stowaway-ssh       # SSH straight in  (password: treasure)
```

Inside the VM, prove it's the real thing:

```bash
uname -a                # its own Linux kernel — not the host's
cat /etc/os-release     # a whole guest OS
exit
```

Then show its **screen** over VNC (opens macOS Screen Sharing):

```bash
just stowaway-vnc
```

Tidy up:

```bash
just stowaway-down      # delete the VM (KubeVirt stays installed)
```

Login for the VM: **`cirros` / `treasure`** (set by cloud-init in the VM
manifest).

---

## 🧯 If something misbehaves

| Symptom | Fix |
| :--- | :--- |
| `dinghy-demo` → `connection refused` | The vcluster API wasn't ready. Wait ~20s after `dinghy-up`, re-run. |
| `stowaway-ssh` → `banner exchange` timeout | VM still booting under emulation. Wait ~30s and re-run. |
| `stowaway-vnc` → viewer doesn't open | Run `open vnc://localhost:5901` yourself; keep the recipe's terminal open (it holds the tunnel). |
| VM stuck `Scheduling` / "no /dev/kvm" | Re-run `just kubevirt-install`; confirm `kubectl -n kubevirt get kv kubevirt -o jsonpath='{.status.phase}'` is `Deployed`. |

## 📁 What's on disk

- `k8s/demos/dinghy-values.yaml` — vcluster helm values.
- `k8s/demos/kubevirt-cr.yaml` — KubeVirt config (`useEmulation: true`).
- `k8s/demos/stowaway-vm.yaml` — the CirrOS `VirtualMachine`.
- All recipes: `just --list | grep -E 'dinghy|stowaway|kubevirt'`.
