#!/bin/bash
# Admiral Bash's Scavenger Hunt Deployer
# Run this right before the afternoon "Paddling Out" lab.

set -e

# Generate a random 6-character secret code
SECRET_CODE=$(LC_ALL=C tr -dc 'A-Z0-9' < /dev/urandom | head -c 6)

# Array of nautical but obscure namespace names
NAMESPACES=("davy-jones-locker" "the-abyss" "kraken-den" "bermuda-triangle" "sunken-galleon" "mermaid-lagoon")
RANDOM_NS=${NAMESPACES[$RANDOM % ${#NAMESPACES[@]} ]}

echo "🏴‍☠️ The Admiral is hiding the treasure chest in namespace: $RANDOM_NS"
echo "🔑 The secret code is: $SECRET_CODE"

# Create the namespace if it doesn't exist
kubectl get ns $RANDOM_NS >/dev/null 2>&1 || kubectl create ns $RANDOM_NS

# Create the Pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: treasure-chest
  namespace: $RANDOM_NS
  labels:
    app: hidden-treasure
spec:
  containers:
  - name: gold
    image: alpine
    command: ["/bin/sh", "-c"]
    args:
    - "while true; do echo 'Arrgh! You found the chest. The secret code is: $SECRET_CODE'; sleep 10; done"
    resources:
      limits:
        memory: "32Mi"
        cpu: "10m"
EOF

echo "✅ Treasure hidden! Tell the students to start hunting with 'kubectl get pods -A' and 'kubectl logs'."
