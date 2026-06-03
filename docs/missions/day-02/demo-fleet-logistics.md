# Demo: Fleet Logistics (the 3-tier walkthrough)

> **Slot:** Day 2 afternoon, replaces (or front-loads) the Lab 03 block — 30 min
> **Audience:** mixed students + faculty
> **Mode:** instructor-led demo, no student keyboards
> **Slides:** [`slides/day-02/gateway-api-personas.md`](../../slides/day-02-gateway-api-personas.html) (show *before* this), [`slides/day-02/drawing-the-fleet.md`](../../slides/day-02-drawing-the-fleet.html)
> **Manifests:** [`fleet-demo/`](fleet-demo/)
> **Setup:** [`scripts/fleet-demo-setup.sh`](../../../scripts/fleet-demo-setup.sh)

Lab 03 (Fleet Logistics) plays beautifully — but **nobody finishes it in the
slot**. Wiring three tiers across three namespaces, proving each silent link,
exposing the frontend through the Gateway, *then* surviving the blockade is more
than an hour of work for a 3-person team. This demo gives the room the **whole
build in 30 minutes** with one keyboard: yours.

It is also the **on-ramp to Day 3 Helm**. Tomorrow's first lab opens with *"paste
your Day 2 Redis Deployment + Service"* and templatizes these exact manifests
into a chart. The manifests in [`fleet-demo/`](fleet-demo/) are deliberately
named `cache` / `backend` / `frontend` — the same keys as Day 3's `values.yaml`.
The closing line writes itself: *"that was ~185 lines of hand-typed YAML for one
app. Tomorrow Hazel stamps the whole fleet from one blueprint."*

## 🧑‍🏫 Instructor Superpower: Build Once, Stamp Many

*Watch me stand the entire stack up by hand — three tiers, real cross-namespace
networking, a public URL. It works, and it's tedious. Hold onto that tedium:
tomorrow you turn this exact pile of YAML into a Helm chart and deploy thirty
identical copies with one command. The demo is the "before"; Helm is the "after."*

## 🛠 Pre-Flight (a few minutes before)

1. **Run the setup script.** It creates the three namespaces, adds the
   `fleet.<domain>` `/etc/hosts` line (so the browser resolves the new hostname),
   and checks the gateway is up:
   ```bash
   LAB_DOMAIN={{ lab_domain }} bash scripts/fleet-demo-setup.sh
   ```
   It prints your live apply order — keep that terminal open.
2. **Warm the images** so the live `apply` isn't waiting on the registry. Easiest
   is to apply the tiers once now, confirm green, then delete the workloads (keep
   the namespaces):
   ```bash
   M=docs/missions/day-02/fleet-demo
   kubectl apply -f $M/cache.yaml -f $M/backend.yaml -f $M/frontend.yaml
   # ...wait for green in k9s, then:
   kubectl delete -f $M/cache.yaml -f $M/backend.yaml -f $M/frontend.yaml
   ```
3. **Open `k9s`** on the projector, and a browser tab ready for `https://fleet.{{ lab_domain }}`.
4. **Note the domain.** The HTTPRoute in `frontend.yaml` is literal
   `fleet.wagbiz.org`. If your `LAB_DOMAIN` isn't `wagbiz.org`, `sed` the hostname
   in `frontend.yaml` to match (the setup script already handled `/etc/hosts`).

## ⏱ The Run-Sheet (30 min)

| Time | Beat | What you do |
| :--- | :--- | :--- |
| 00:00 – 03:00 | **Why Services exist** | Pull up `drawing-the-fleet` Part II. Pods get a new IP every restart — you can't hardcode that. A **Service** is the stable name in front of churning Pods. Introduce the three roles: **Storehouse** (cache) → **Ledger** (backend) → **Radar** (frontend). |
| 03:00 – 08:00 | **Tier 1 — Storehouse** | `kubectl apply -f $M/cache.yaml`. In `k9s`, watch Redis go green. Then the key idea: `kubectl get endpoints cache -n fleet-storehouse` — the Service found the Pod **by label**, not by IP. Say the DNS name out loud: `cache.fleet-storehouse.svc.cluster.local:6379`. |
| 08:00 – 14:00 | **Tier 2 — Ledger + the silent break** | `kubectl apply -f $M/backend.yaml`. podinfo goes green. "Done? Let's see." **Break it live:** `kubectl set env deploy/backend -n fleet-ledger CACHE_URL=tcp://cache.fleet-storehousE...` (one typo'd letter). Pod re-rolls — **still green**. Now prove it's dead: shell in (`k9s` → `s`) and `nslookup cache.fleet-storehousE...` → fails; `nc -z -v cache.fleet-storehouse... 6379` → succeeds. "Green pod, dead link. *This* is what ate your afternoon." Fix it with `set env` back to the correct name; re-run `nc` → succeeded. |
| 14:00 – 16:00 | **Tier 3 — Radar (deploy)** | `kubectl apply -f $M/frontend.yaml`. Frontend goes green. Prove the chain: shell into the frontend pod and `wget -qO- http://backend.fleet-ledger.svc.cluster.local:9898/version` → a JSON reply means the Ledger is reachable through two namespaces. |
| 16:00 – 22:00 | **Gateway API — the part that stumped you** | The marquee fix. See the detailed beats below. |
| 22:00 – 23:00 | **The Helm bridge** | Count it live: `cat $M/namespaces.yaml $M/cache.yaml $M/backend.yaml $M/frontend.yaml \| grep -vcE '^\s*#\|^\s*$'` → ~185 lines of hand-typed YAML across **four files** just to stand up **one** app in three namespaces (six files once you add the blockade). "Tomorrow Hazel does the whole stack from one blueprint and `helm install`. That's the entire reason Helm exists." |
| 23:00 – 29:00 | **The Blockade finale** | `kubectl apply -f $M/blockade.yaml`. Refresh the browser — the page is **dead**, but every pod is still green in `k9s`. "The Admiral locked the doors." Recover **one allow-rule at a time** so the room sees the chain heal: apply `allow-rules.yaml`, then re-run the `nc` / `wget` proofs and refresh the browser. Back to a live page. |
| 29:00 – 30:00 | **Hand off to Day 3** | "Tomorrow you don't type any of this. You hand it to Hazel." |

### Gateway API segment (16:00 – 22:00) — narrate, don't just apply

This is the beat the furthest teams got stuck on yesterday. Frame it that way:
*"Last session this was the wall. Watch — it's four fields."* You already showed
the [persona slides](../../slides/day-02-gateway-api-personas.html); this is the
hands-on half.

1. **Recap the roles (20 sec).** `kubectl get gateway -n admin-tools` — one
   gateway, owned by "IT," shared by everyone. *You* only write the HTTPRoute.
2. **HTTPRoute anatomy.** Open `frontend.yaml` and point at the four fields that
   do all the work:
   - `parentRefs` → which Gateway (here: `main-gateway` in `admin-tools`)
   - `hostnames` → the URL the browser uses (`fleet.{{ lab_domain }}`)
   - `rules.matches` → which paths (`/`)
   - `rules.backendRefs` → which ClusterIP Service + port (`frontend:8080`)
   "This is the manifest you couldn't picture — that's all it is."
3. **Cross-namespace attachment.** The route lives in `fleet-radar`, but
   `parentRefs` points at a gateway in `admin-tools`. That only works because the
   gateway's listener says `allowedRoutes.namespaces.from: All` — **the gateway
   opted in to accepting your route.** (Show: `kubectl get gateway main-gateway
   -n admin-tools -o yaml | grep -A2 allowedRoutes`.)
4. **Live debugging — the gateway's silent break.** `kubectl describe httproute
   fleet-radar -n fleet-radar` → `Accepted=True`, `ResolvedRefs=True`. Now break
   the backend port live: `kubectl patch httproute fleet-radar -n fleet-radar
   --type=json -p='[{"op":"replace","path":"/spec/rules/0/backendRefs/0/port","value":9999}]'`.
   Re-describe → `ResolvedRefs=False`; the browser 503s. "Same silent-break lesson,
   one layer up — the route attached fine, it just points at nothing." Patch it
   back to `8080`.
5. **The `/etc/hosts` reality.** A brand-new hostname isn't in any DNS server —
   that's why the setup script added one `/etc/hosts` line (IP borrowed from
   `gitea.{{ lab_domain }}`). *Now* open `https://fleet.{{ lab_domain }}` and the
   page loads through the gateway. "This line was the other thing nobody had —
   the route was perfect, the name just didn't resolve."

## 📎 What the room takes away

- A **Service** is a stable name in front of churning Pods; tiers talk **only**
  through Service DNS names, never IPs.
- A **wrong DNS name doesn't crash anything** — you must *prove* a link with
  `nslookup` / `nc` / `wget`, not assume it.
- **Gateway API by role:** IT owns the Gateway; you write one HTTPRoute. The four
  fields, the cross-namespace attachment, and the `/etc/hosts` step that the lab
  glossed over.
- **Why Helm exists:** they just watched the tedium Helm removes.

## 🪢 Callbacks for the rest of the week

- **Day 3 Helm lab (Lab 01):** open with *"remember the six files I typed yesterday?
  Paste them in — Hazel turns them into one blueprint."* The `cache`/`backend`/
  `frontend` names line up with the chart's `values.yaml` on purpose.
- **Day 3 ArgoCD lab:** the `argocd-route` HTTPRoute they'll see is the same shape
  as the one you wrote live here.
- **Day 4 capstone:** the NetworkPolicy blockade is the same idea as the chaos
  experiments — additive policy, recover by adding allow-rules.

## 🧯 If something goes wrong

- **`apply` hangs on ContainerCreating.** Image still pulling — you skipped the
  pre-flight warm. Narrate it as "first pull is slow" and keep talking; it lands.
- **Browser shows 404 / 503, not the page.** `kubectl describe httproute
  fleet-radar -n fleet-radar`. `ResolvedRefs=False` → wrong Service name/port in
  `backendRefs`. `Accepted=False` → check `parentRefs` (name `main-gateway`,
  namespace `admin-tools`).
- **Browser can't resolve the host at all.** The `/etc/hosts` line is missing or
  the domain doesn't match `frontend.yaml`'s hostname. Re-run the setup script;
  confirm `getent hosts fleet.{{ lab_domain }}` returns the cluster IP.
- **Browser TLS warning.** Offline/self-signed cert mode — expected; click through,
  or note the wildcard cert covers `*.{{ lab_domain }}`.
- **After `allow-rules.yaml` the page is still dark.** The Radar rule must allow
  `admin-tools` (Traefik), *not* a teammate namespace — gateway traffic is
  rewritten to come from Traefik. See the comment block in `allow-rules.yaml`.

## 🧹 Teardown

```bash
bash scripts/fleet-demo-setup.sh teardown
# or: kubectl delete ns fleet-storehouse fleet-ledger fleet-radar
```
