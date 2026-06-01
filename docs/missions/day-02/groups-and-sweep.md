# Day 2 — Groups & Namespace Sweep (Instructor Crib)

Pre-class prep for the Day 2 morning. Two things to land before the CrashLoop game runs:
the **3-tier teams** for Lab 03, and a quick **namespace sweep** so the broken-pod injector hits everyone.

---

## Team Assignments (Lab 03: Fleet Logistics)

12 students (11 roster + instructor joining the short team) → **4 teams of 3**. Each
member's `BACKEND_URL` / `CACHE_URL` env var needs their teammate's namespace, so this
table doubles as the per-team DNS cheat sheet.

| Team | A · Storehouse (`redis:alpine`) | B · Ledger (`stefanprodan/podinfo`) | C · Radar (`paulbouwer/hello-kubernetes`) |
|---|---|---|---|
| **Albatross** | pamela → `student-pamela` | joey → `student-joey` | mark → `student-mark` |
| **Barracuda** | shen → `student-shen` | asad → `student-asad` | tina → `student-tina` |
| **Cormorant** | niall → `student-niall` | mohammad → `student-mohammad` | josh → `student-josh` |
| **Dolphin** | christina → `student-christina` | divya → `student-divya` | eric → `student-eric` |

**Service DNS each tier needs to wire up:**

- Student B's `CACHE_URL` → `tcp://<A's-svc>.<A's-namespace>.svc.cluster.local:6379`
- Student C's `BACKEND_URL` → `http://<B's-svc>.<B's-namespace>.svc.cluster.local:<port>`

**Day-of:** project or print this table. Don't burn 5 min on shuffling — call out
the teams and have students cluster physically.

---

## Namespace Sweep (Day 2, ~09:00, 5 min)

The crashloop and network-blockade scripts target every namespace matching `^student-`.
Any student whose Day 1 setup didn't land won't get a `leaky-ship` pod and will sit out
the triage exercise. Sweep before injecting.

**1. Inventory what's actually in the cluster** (run from the podium):

```bash
kubectl get ns -o name | grep '^namespace/student-' | sort
```

**2. Diff against the roster:**

```bash
# expected from students.csv
awk -F, '!/^#/ && NF>=2 {gsub(/ /,"",$1); print "namespace/student-"$1}' \
    scripts/students.csv | sort > /tmp/expected-ns.txt

# actual in cluster
kubectl get ns -o name | grep '^namespace/student-' | sort > /tmp/actual-ns.txt

diff /tmp/expected-ns.txt /tmp/actual-ns.txt
```

**3. Heal anyone missing** — `provision-students.sh` is idempotent per its own header,
safe to run mid-class on a single student:

```bash
./scripts/provision-students.sh --student <username>
```

**4. Have the student prove access from their VM:**

```bash
kubectl get pods -n student-<username>
```

A 401/403 means their Day 1 Rancher kubeconfig copy didn't stick. Re-walk the Rancher UI
step, or hand them a fallback via:

```bash
CLUSTER_SERVER=https://<public-ip>:6443 \
    ./scripts/generate-student-kubeconfig.sh <username>
```

**5. Only then** run the CrashLoop injector:

```bash
./scripts/day-02-crashloop-game.sh
```

Its `grep -E '^student-'` will now hit every roster member.
