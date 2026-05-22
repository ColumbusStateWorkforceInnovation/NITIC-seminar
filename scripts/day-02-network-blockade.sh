#!/bin/bash
# Admiral Bash's Network Blockade
# Run this during the afternoon "Fleet Logistics" group activity when everyone has their 3-tier app working.

set -e

echo "🏴‍☠️ Deploying the Network Blockade! Shutting down cross-namespace communication..."

# Apply a default deny-all-ingress NetworkPolicy to all student namespaces
# Target ONLY student namespaces (student-<username>, created by
# provision-students.sh). A positive match is safer than the old exclude-list,
# which missed cattle-system / cert-manager / chaos-mesh and would have
# blockaded Rancher and other infrastructure.
NAMESPACES=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E '^student-' || true)

for NS in $NAMESPACES; do
  echo "Blockading namespace: $NS"
  
  cat <<EOF | kubectl apply -n $NS -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: admiral-blockade
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
done

echo "✅ Blockade deployed. The students' 3-tier apps are now broken!"
echo "They must use aichat to learn how to write a NetworkPolicy that allows traffic from their group members' namespaces."
