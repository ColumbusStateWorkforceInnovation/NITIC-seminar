# 🏴‍☠️ Podium Cheat-Sheet — Lab 02: The Automated Shipyard (ArgoCD)

**Day 3 · 2:45–4:15 PM** · keep this open during the lab.

---

## 🔑 Read out to the room

> **ArgoCD URL:** `argocd.wagbiz.org` — everyone logs in as **`admin`** (SSO logins are read-only today)
>
> **ArgoCD admin password:**  `________________________`
>
> _Fill in before class:_ `./scripts/preflight-argocd-lab.sh` prints it, or
> `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`

---

## ✅ Pre-flight (run once, before class)

```bash
./scripts/preflight-argocd-lab.sh      # checks all of the below + prints the password
```

- [ ] **`just grant-raider`** applied — Step 4 (the Raid) is dead without it. *Verify:* `just check-access <name>` or the preflight script.
- [ ] **`just clear-decks`** ran (night before) — else Lab 01 `helm install` exceeds the 500m CPU quota and pods sit **Pending** (students read this as "I broke it").
- [ ] **Self-Heal ON** for every student Application — the entire Raid is only safe because sabotage self-reverts.
- [ ] ArgoCD + Gitea pods healthy.
- [ ] Tear down after Day 3: **`just revoke-raider`**.

---

## 🗺️ Run of show

| Time | Beat |
| :--- | :--- |
| **1:45–2:45** | **Part 1** — push Lab 01 chart to Gitea → create ArgoCD App. *Everyone Healthy/Synced by the break.* |
| **2:45–3:00** | ☕ Break |
| **3:00–~3:20** | **The Mutiny (solo)** — scale/delete your *own* deployment, watch Self-Heal drag it back. |
| **~3:20–3:40** | **The Raid (collab)** — delete a *crewmate's* deployment; it heals. Punchline → |
| | **Close the loop** — edit chart, push, watch it roll out live (~2 min). |
| **3:40–4:15** | Lecture: The Quartermaster's Manifest. |

**Landing line:** *"`kubectl` is a suggestion; **Git is the law.** The only durable way to change a crewmate's fleet is a PR they merge."*

---

## ⚠️ The four gotchas students WILL hit

1. **Two Gitea URLs — don't swap them.**
   - Push (from client VM): `https://gitea.wagbiz.org/<name>/island-stack.git`
   - ArgoCD Repository URL (inside cluster): `http://gitea-http.admin-tools.svc.cluster.local:3000/<name>/island-stack.git` — **http**, `.svc.cluster.local`.
   - *"repo not found" / "failed to resolve"* = this URL, **or** they left the repo **private** (must be public).
2. **No Git password.** SSO accounts have none → mint a **PAT** (Settings → Applications → `repository: Read+Write`), paste *that* as the push password.
3. **Branch is `maindeck`, not `main`** — in `git init -b maindeck` **and** ArgoCD's **Revision** field.
4. **Scrap the manual release first:** `helm uninstall my-stack -n student-<name>` before creating the App, or two captains fight over one fleet (double pods, blown quota).

---

## 🚨 The one thing to police

Everyone is on the shared **`admin`** login, so anyone *can* delete a neighbor's Application card — **don't let them.**

- Raid with **`kubectl`** on a **deployment** → heals. ✅
- Clicking **Delete** on an **Application card** + Prune → tears down the whole stack, does **NOT** self-recover. ❌

---

## 🧰 Commands you'll demo / paste

```bash
# Mutiny (solo) — your own namespace
kubectl scale deployment <name>-cache --replicas=10 -n student-<name>
kubectl delete deployment <name>-cache -n student-<name>

# Raid (collaborative) — a crewmate's namespace
kubectl delete deployment <their-name>-cache -n student-<their-name>

# The App object behind the "+ NEW APP" form (the shipyard is just Kubernetes):
#   repoURL:  http://gitea-http.admin-tools.svc.cluster.local:3000/<name>/island-stack.git
#   revision: maindeck   path: .   namespace: student-<name>
#   syncPolicy.automated: { prune: true, selfHeal: true }
```

**Done when:** every student's app shows **Healthy / Synced** *and* they can articulate Captain's Log (desired/Git) vs. Crew's Actions (live/cluster).
