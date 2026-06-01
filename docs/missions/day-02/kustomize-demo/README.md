# Kustomize Demo — Reference Manifests

These are the manifests the instructor uses live during the 10-minute
Kustomize slot at the top of Day 2 (09:10 – 09:20). The full runbook (timing,
talking points, commands) lives in
[`../demo-kustomize.md`](../demo-kustomize.md).

## Layout

```text
kustomize-demo/
├── base/
│   ├── raft-pod.yaml           ← the Day 1 raft Pod (image tag :v1)
│   └── kustomization.yaml      ← references just raft-pod.yaml
└── overlays/
    └── all-students/           ← the demo: one images: newTag: v2 override
        └── kustomization.yaml
```

## Quick verify (instructor pre-flight)

```bash
cd docs/missions/day-02/kustomize-demo
kubectl kustomize base/                       # prints the placeholder my-raft Pod (v1)
kubectl kustomize overlays/all-students/      # prints the placeholder my-raft Pod, tag :v2
```

If both render cleanly with no errors, the demo is ready.

## Apply loop (the demo itself)

Each iteration rewrites the overlay's image override to point at THAT
student's v2 image, then applies it into THAT student's namespace. The
existing `my-raft` Pod (deployed in Day 1 Lab 02) is updated in-place.

```bash
# Either run this at 07:00 (silent — students walk in to v2)
# or run it live at 09:11 with a student's k9s on the projector.
cd docs/missions/day-02/kustomize-demo
for ns in $(kubectl get ns -l role=student -o name); do
  student="${ns#namespace/student-}"
  ( cd overlays/all-students && \
    kustomize edit set image \
      "harbor.wagbiz.org/raft-fleet/raft=harbor.wagbiz.org/raft-fleet/${student}:v2" && \
    kubectl apply -k . -n "${ns#namespace/}" )
done

# Reset the overlay back to the placeholder shape so the next render is clean.
( cd overlays/all-students && \
  kustomize edit set image \
    "harbor.wagbiz.org/raft-fleet/raft=harbor.wagbiz.org/raft-fleet/raft:v2" )
```

## Stale files

This folder previously held a longer 15-min Day 3 demo (per-student
overlays for a Deployment + Service). When the demo moved to Day 2 and
shrank to 10 min, the older example files were left behind because the
authoring sandbox can't delete files. They are:

- `base/deployment.yaml`, `base/service.yaml`
- `overlays/student-01/`, `overlays/student-02/`, `overlays/harder-mode/`

Run [`../../../../scripts/cleanup-kustomize-demo-stale.sh`](../../../../scripts/cleanup-kustomize-demo-stale.sh)
once to remove them. The active demo (Day 2 morning) only uses what's
listed in the Layout section above.
