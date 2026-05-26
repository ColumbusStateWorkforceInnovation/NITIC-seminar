# Lab 01: Drafting the Blueprint

Yesterday your alliance hand-built a 3-tier fleet — a Deployment and a Service for every tier, every line typed by hand. It worked. But it does not *scale*.

Meet **Hazel**, the island's shipwright (Helm). Hazel does not build one ship at a time. She drafts a **blueprint** once, and then stamps out an entire fleet from it. In this lab you will turn your hand-written Day 2 manifests into a reusable Helm chart — a single blueprint that deploys your whole stack into any namespace with one command.

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
studentName: blackbeard

cache:
  replicaCount: 1
  image: redis:alpine

backend:
  replicaCount: 1
  image: stefanprodan/podinfo:latest

frontend:
  replicaCount: 1
  image: paulbouwer/hello-kubernetes:1.10
```

## Step 5: Launching the Fleet

1. Render the chart **without** installing it, to check your braces:
   `helm template ./island-stack`
   Read the output — it should be plain, valid YAML with every placeholder filled in.
2. Install the release into your namespace:
   `helm install my-stack ./island-stack -n <your-name>`
3. Confirm Helm is tracking it:
   `helm list -n <your-name>`
4. Check `k9s` — your cache tier should be sailing.

## Step 6: Repeat the Pattern

Cast the other two molds yourself: `templates/backend.yaml` and `templates/frontend.yaml`. Same pattern — paste your Day 2 YAML, swap hardcoded values for `.Values` references. Then upgrade the release to roll them out:

`helm upgrade my-stack ./island-stack -n <your-name>`

## 🏁 Gamification Checkpoint: The Templating Speed Run

Hazel does not rebuild ships — she *upgrades* them. There are two ways to turn a knob:

- Edit `values.yaml` and run `helm upgrade my-stack ./island-stack -n <your-name>`
- Or override on the fly: `helm upgrade my-stack ./island-stack -n <your-name> --set cache.replicaCount=5`

**The Race:** Be the first pirate to push your cache tier to **5 replicas** — and prove it in `k9s`! Bonus round: explain to the room *why* `--set` beats editing the file in a hurry.

---
**🧹 Cleanup:** One blueprint, one command to scrap the whole fleet: `helm uninstall my-stack -n <your-name>`. Notice Helm removes *every* object it created — no orphaned Services left drifting.
