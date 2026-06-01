#!/bin/bash
# ============================================================
# ⚓ Admiral Bash's Island Adventure — Ghost Ship Demo Setup
# ============================================================
#
# PURPOSE:
#   Pre-stages the Ghost Ship immutability demo for Day 1 Lab 02
#   (~16:10 AM, right after students set up their cluster access).
#
#   Creates an 'instructor-demo' namespace with an nginx pod called
#   'my-raft' that the instructor demos on — so student namespaces
#   aren't disturbed. Idempotent — safe to re-run.
#
# USAGE:
#   bash scripts/instructor-demo-setup.sh
#
# RUN IT:
#   Before class, or anywhere during the lunch break — anywhere
#   before 16:00 on Day 1. The pod sits around using ~50m CPU /
#   64Mi memory until you tear it down with:
#     kubectl delete namespace instructor-demo
# ============================================================

set -e

NAMESPACE="instructor-demo"
MANIFEST="/tmp/ghost-ship-demo-pod.yaml"

echo "⚓ Setting up Ghost Ship demo namespace..."

# Idempotent namespace creation.
if kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
    echo "   ↪ Namespace '${NAMESPACE}' already exists."
else
    kubectl create namespace "$NAMESPACE" > /dev/null
    echo "   ✅ Namespace '${NAMESPACE}' created."
fi

# Persist the demo pod.yaml so the demo's `kubectl apply -f` step uses a real
# file on disk (matches what the students will do in their own labs).
cat > "$MANIFEST" <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: my-raft
  namespace: instructor-demo
  labels:
    run: my-raft
spec:
  containers:
  - name: my-raft
    image: nginx:alpine
    ports:
    - containerPort: 80
    resources:
      limits:
        memory: "64Mi"
        cpu: "50m"
      requests:
        memory: "32Mi"
        cpu: "25m"
YAML

kubectl apply -f "$MANIFEST" > /dev/null
echo "   ✅ Pod 'my-raft' deployed to namespace '${NAMESPACE}'."
echo "   📄 Manifest at: ${MANIFEST}"

# Wait briefly for it to be Ready so the demo doesn't open on a Pending pod.
if kubectl wait --for=condition=Ready "pod/my-raft" -n "$NAMESPACE" --timeout=60s > /dev/null 2>&1; then
    echo "   ⚓ Pod is Ready."
else
    echo "   ⚠️  Pod did not reach Ready within 60s — check 'kubectl describe pod my-raft -n ${NAMESPACE}' before you start the demo."
fi

cat <<DEMO

═════════════════════════════════════════════════════════════
🎬 Ghost Ship demo — your live script

   # 1. Board the running pod
   kubectl exec -n ${NAMESPACE} -it my-raft -- /bin/sh

       # inside the container:
       echo '<h1>I WAS MANUALLY HACKED</h1>' > /usr/share/nginx/html/index.html
       exit

   # 2. Prove the hack stuck (Pod IPs are unreachable from the VM — use exec)
   kubectl exec -n ${NAMESPACE} my-raft -- cat /usr/share/nginx/html/index.html

   # 3. The storm hits
   kubectl delete pod -n ${NAMESPACE} my-raft

   # 4. Re-apply from the immutable manifest
   kubectl apply -f ${MANIFEST}

   # 5. Reveal: the hack is gone, original page is back
   kubectl exec -n ${NAMESPACE} my-raft -- cat /usr/share/nginx/html/index.html

   The page reads "Welcome to nginx!" — proving anything you do INSIDE a
   running pod evaporates the moment it respawns. Image + manifest are
   the only sources of truth.

Tear down after the lab:
   kubectl delete namespace ${NAMESPACE}
═════════════════════════════════════════════════════════════

DEMO
