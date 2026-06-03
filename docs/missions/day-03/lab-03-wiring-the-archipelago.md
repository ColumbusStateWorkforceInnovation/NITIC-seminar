# Lab 03: Wiring the Archipelago *(optional / reference)*

> **Not in the main Day 3 flow.** Clabernetes is now introduced as *one item on
> the shelf* in the closing **Quartermaster's Manifest** lecture — named as the
> EVE-NG/GNS3 replacement for the networking faculty, not run hands-on. This lab
> is kept as an optional deep-dive for a fast room, a networking-heavy cohort, or
> a curious student after hours.
>
> **Difficulty: Advanced.** This is the heaviest anchor Admiral Bash drops all week.

GitOps can deploy web apps. Big deal. Can it deploy a **commercial router**?

Traditional networking labs need GNS3, EVE-NG, or a rack of physical Cisco gear — heavy, expensive, impossible to give every student. **Clabernetes** changes that: it runs full [Containerlab](https://containerlab.dev) network topologies *inside* Kubernetes. Real Nokia SR Linux router nodes, summoned by a few lines of YAML.

In this lab you will use ArgoCD to deploy a two-router topology — `router-port` and `router-starboard` — and lay a "deep-sea cable" between the islands.

## 🧑‍🏫 Instructor Superpower: Replacing the Hardware Lab

*"Network as Code" works exactly like "App as Code." A faculty member can provision a complete, isolated multi-router BGP/OSPF lab for every student by committing a YAML file. No EVE-NG. No physical hardware. Just Containerlab, scaled by Kubernetes GitOps.*

## ⚓ Prerequisites

- **Clabernetes** must be installed in the cluster. It is *not* part of `deploy-core` — your instructor installs it from `k8s/core-tools/clabernetes-values.yaml`.
- The SR Linux image (`ghcr.io/nokia/srlinux`) is ~1.5 GB. The first deploy on a fresh cluster is slow — be patient.

## Step 1: Draft the Topology

A Clabernetes `Topology` is a Kubernetes object that *contains* a Containerlab topology. Create `archipelago.yaml`:

```yaml
apiVersion: clabernetes.containerlab.dev/v1alpha1
kind: Topology
metadata:
  name: archipelago
spec:
  definition:
    containerlab: |
      name: archipelago
      topology:
        nodes:
          router-port:
            kind: nokia_srlinux
            image: ghcr.io/nokia/srlinux:latest
          router-starboard:
            kind: nokia_srlinux
            image: ghcr.io/nokia/srlinux:latest
        links:
          - endpoints: ["router-port:e1-1", "router-starboard:e1-1"]
```

That `links` line is the physical cable between the two ships. Everything else is just YAML.

## Step 2: Let the Shipyard Summon the Fleet

Stay on theme — do not `kubectl apply` this by hand. Commit it to your Gitea repo and let ArgoCD deploy it, exactly like Lab 02:

```bash
cp archipelago.yaml island-stack/
cd island-stack
git add archipelago.yaml
git commit -m "Summon the ghost fleet"
git push
```

Watch ArgoCD sync. Clabernetes turns each node into a running pod. Check `k9s` — you should see `archipelago-router-port` and `archipelago-router-starboard` come up.

## Step 3: Board the Router

You can `kubectl exec` straight past the Kubernetes shell and drop into the router's **real commercial CLI**:

```bash
kubectl exec -it deploy/archipelago-router-port -n <your-name> -- sr_cli
```

You are now at the Nokia SR Linux prompt — the same CLI used in production carrier networks.

## Step 4: Lay the Deep-Sea Cable

Configure the link interface on **`router-port`**. SR Linux configuration is deep vendor syntax — the Boatswain will not derive this for you, so it is given in full:

```text
enter candidate
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 address 10.0.0.1/30
set / interface lo0 subinterface 0 ipv4 address 10.255.0.1/32
set / network-instance default interface ethernet-1/1.0
set / network-instance default interface lo0.0
commit now
```

Now exec into **`router-starboard`** (`...-router-starboard ... -- sr_cli`) and configure the other end — note the mirrored addresses:

```text
enter candidate
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 address 10.0.0.2/30
set / interface lo0 subinterface 0 ipv4 address 10.255.0.2/32
set / network-instance default interface ethernet-1/1.0
set / network-instance default interface lo0.0
commit now
```

## Step 5: Chart the Trade Route (Static Route)

Each router can reach its *own* loopback, but not the other island's. Add a static route. On **`router-port`**:

```text
enter candidate
set / network-instance default next-hop-groups group ISLAND nexthop 1 ip-address 10.0.0.2
set / network-instance default static-routes route 10.255.0.2/32 next-hop-group ISLAND
commit now
```

Do the mirror on **`router-starboard`** — point it at `10.0.0.1` and route toward `10.255.0.1/32`.

## Step 6: Signal Across the Water

From the `router-port` CLI, ping `router-starboard`'s loopback:

```text
ping 10.255.0.2 network-instance default
```

Replies coming back means the deep-sea cable is **live** — two commercial routers, talking across a route you charted, all running inside Kubernetes, all deployed by GitOps.

---
**Done when:** your alliance lands a successful loopback-to-loopback ping across the archipelago. Stretch goal: swap the static route for **BGP peering** between the two `default` network-instances.
