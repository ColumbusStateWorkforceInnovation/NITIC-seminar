# Lab 01: Drafting the Blueprint

Yesterday your alliance hand-built a 3-tier fleet — a Deployment and a Service for every tier, every line typed by hand. It worked. But it does not *scale*.

Meet **Hazel**, the island's shipwright (Helm). Hazel does not build one ship at a time. She drafts a **blueprint** once, and then stamps out an entire fleet from it. In this lab you will turn your hand-written Day 2 manifests into a reusable Helm chart — a single blueprint that deploys your whole stack into any namespace with one command.

!!! info "Two names, don't mix them up"
    Throughout Day 3, **`<name>`** is your short handle — the same one you've
    used all week (e.g. `blackbeard`). Your **namespace is `student-<name>`**
    (e.g. `student-blackbeard`). So your cache Deployment is named
    `<name>-cache` and it lives in namespace `student-<name>`. Wherever you see
    `-n student-<name>`, substitute your handle.

## 🧑‍🏫 Instructor Superpower: The Master Blueprint

*Instead of recreating 30 distinct lab environments for 30 students, you write **one** chart. Change the `studentName` in a `values.yaml` and you have spun up an identical, isolated environment. Thirty databases, thirty backends, thirty frontends — from one blueprint and one command.*

## Step 1: Scaffolding the Blueprint

Helm can generate a starter chart for you — the same "don't memorize it, generate it" philosophy you have used all week.

1. Generate a fresh chart:
   `helm create island-stack`
2. Look at what Hazel gave you:
   ```text
   island-stack/
   ├── Chart.yaml          # the blueprint's name + version
   ├── values.yaml         # the knobs you can turn
   └── templates/          # the molds — YAML with placeholders
   ```
3. Ask the Boatswain to explain the three pieces: *"Boatswain, what is the difference between Chart.yaml, values.yaml, and the templates folder in a Helm chart?"*

## Step 2: Clearing the Decks

The generated chart is a full Nginx example. You only want the structure.

1. Delete the sample templates so you have a clean hull to work in:
   `rm island-stack/templates/*.yaml island-stack/templates/tests/*.yaml`
2. Leave `island-stack/templates/_helpers.tpl` in place — that file holds shared naming logic.

## Step 3: Casting the First Mold (The Cache Tier)

You will templatize **one** tier together — the Redis cache from Day 2 — then repeat the pattern for the others.

Create `island-stack/templates/cache.yaml`. Paste in your Day 2 Redis Deployment + Service, then replace the **hardcoded** values with placeholders that read from `values.yaml`.

{% raw %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.studentName }}-cache
spec:
  replicas: {{ .Values.cache.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.studentName }}-cache
  template:
    metadata:
      labels:
        app: {{ .Values.studentName }}-cache
    spec:
      containers:
      - name: redis
        image: "{{ .Values.cache.image }}"
        ports:
        - containerPort: 6379
```
{% endraw %}

!!! warning "The Brace Trap"
    Helm uses {% raw %}`{{ double braces }}`{% endraw %}. Get the spacing or the dots wrong and the
    whole release fails to render. **This is the trap** — the Boatswain will
    *not* type the braces for you. Ask it *what* a value reference looks like,
    then write it yourself.

## Step 4: Labeling the Knobs (`values.yaml`)

Open `island-stack/values.yaml`, delete everything Hazel generated, and define the knobs your template just referenced:

```yaml
studentName: blackbeard      # your short handle — the deployment name prefix

cache:
  replicaCount: 1
  image: redis:7.2-alpine

backend:
  replicaCount: 1
  image: stefanprodan/podinfo:6.7.0

frontend:
  replicaCount: 1
  image: paulbouwer/hello-kubernetes:1.10
```

!!! warning "Pin the same tags you ran on Day 2"
    Use these exact image tags — `redis:7.2-alpine` and
    `stefanprodan/podinfo:6.7.0` — not `:latest` or `:alpine`. A floating tag
    means two students can pull two different images from the "same" blueprint,
    and tomorrow's GitOps lab depends on the chart rendering identically every
    time.

## Step 5: Launching the Fleet

!!! warning "Empty your harbor first"
    Your namespace has a small CPU budget (enough for about five small pods). If
    **Day 2's** hand-built fleet is still sailing in there, the new stack won't
    fit and pods will sit stuck **Pending**. Scrap the old ships before you
    launch the blueprint:
    ```bash
    kubectl delete deploy,svc --all -n student-<name>
    ```
    (Check with `kubectl get pods -n student-<name>` — it should be empty.)

1. Render the chart **without** installing it, to check your braces:
   `helm template ./island-stack`
   Read the output — it should be plain, valid YAML with every placeholder filled in.
2. Install the release into your namespace:
   `helm install my-stack ./island-stack -n student-<name>`
3. Confirm Helm is tracking it:
   `helm list -n student-<name>`
4. Check `k9s` — your cache tier should be sailing.

## Step 6: Repeat the Pattern

Cast the other two molds yourself: `templates/backend.yaml` and `templates/frontend.yaml`. Same pattern — paste your Day 2 YAML, swap hardcoded values for `.Values` references. Then upgrade the release to roll them out:

`helm upgrade my-stack ./island-stack -n student-<name>`

!!! note "Leave the HTTPRoute out of the frontend chart"
    On Day 2 your frontend tier came with a Gateway API **HTTPRoute** (the
    "front door"). **Do not** template that into your chart — copy only the
    frontend **Deployment** and **Service**. This week's Helm/GitOps labs are
    about the blueprint and the self-healing loop, not ingress; a per-student
    route drags in hostnames, the shared `main-gateway`, and TLS, any of which
    can leave your ArgoCD app stuck **OutOfSync** tomorrow. Your stack is "done"
    when the three Deployments are running — you don't need a browser URL.

## Two Ways to Turn a Knob

Hazel does not rebuild ships — she *upgrades* them. There are two ways to change a value:

- Edit `values.yaml` and run `helm upgrade my-stack ./island-stack -n student-<name>`
- Or override on the fly: `helm upgrade my-stack ./island-stack -n student-<name> --set cache.replicaCount=5`

**Try it:** scale your cache tier to **3 replicas** with the `--set` form, then confirm in `k9s`. (Three is about all your namespace's CPU budget allows on top of the other two tiers — push higher and the extra pods sit **Pending**, which is the quota doing its job, not a bug. Scale back to 1 when you're done.) Then think through *why* the file-vs-flag distinction matters — one survives a redeploy, the other doesn't.

---
**🧹 Cleanup:** One blueprint, one command to scrap the whole fleet: `helm uninstall my-stack -n student-<name>`. Notice Helm removes *every* object it created — no orphaned Services left drifting.
