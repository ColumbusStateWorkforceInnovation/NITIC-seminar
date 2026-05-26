#!/bin/bash
# Admiral Bash's CrashLoopBackOff Injector
# Run this before the morning "Radar Room" lab.

set -e

echo "🏴‍☠️ Injecting the 'CrashLoopBackOff' virus into all student namespaces..."

# Target ONLY student namespaces (student-<username>, created by
# provision-students.sh). A positive match is safer than an exclude-list,
# which missed cattle-system / cert-manager and would inject the broken
# Deployment into Rancher's own infrastructure namespaces.
NAMESPACES=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E '^student-' || true)

for NS in $NAMESPACES; do
  echo "Injecting into namespace: $NS"
  
  cat <<EOF | kubectl apply -n $NS -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: leaky-ship
  labels:
    app: leaky-ship
spec:
  replicas: 1
  selector:
    matchLabels:
      app: leaky-ship
  template:
    metadata:
      labels:
        app: leaky-ship
    spec:
      containers:
      - name: leaky-container
        image: alpine
        command: ["/bin/sh", "-c"]
        # The deliberate bug: the LAST command is 'cat' on a missing file, so the
        # container exits non-zero (status Error) and the Deployment keeps
        # restarting it -> CrashLoopBackOff. Keep 'cat' last: if anything (e.g.
        # an echo) runs after it, the shell exits 0 and the pod reads
        # "Completed" instead of looking broken.
        args:
        - "echo 'Starting ship engines...'; sleep 2; cat /nonexistent/config.txt"
        resources:
          limits:
            memory: "32Mi"
            cpu: "10m"
EOF
done

echo "✅ Virus injected. Tell the students to open k9s and find the broken pod!"
