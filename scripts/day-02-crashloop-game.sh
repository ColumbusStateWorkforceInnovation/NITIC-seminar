#!/bin/bash
# Admiral Bash's CrashLoopBackOff Injector
# Run this before the morning "Radar Room" lab.

set -e

echo "🏴‍☠️ Injecting the 'CrashLoopBackOff' virus into all student namespaces..."

# Get all namespaces except system ones
NAMESPACES=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vE 'kube-|default|admin|argocd|local')

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
        # The deliberate bug: missing a semicolon before 'done' or trying to run a bad command
        args:
        - "echo 'Starting ship engines...'; sleep 2; cat /nonexistent/config.txt; echo 'This will never print because cat failed!'"
        resources:
          limits:
            memory: "32Mi"
            cpu: "10m"
EOF
done

echo "✅ Virus injected. Tell the students to open k9s and find the broken pod!"
