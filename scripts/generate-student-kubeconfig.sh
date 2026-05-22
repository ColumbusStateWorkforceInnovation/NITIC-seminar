#!/bin/bash
# Admiral Bash's Adventure - Fallback Kubeconfig Generator
# Generates native Kubeconfigs bound to specific namespaces for students.
# Use this if Rancher Auth fails!

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <student-name>"
  echo "Example: $0 eric"
  exit 1
fi

STUDENT_NAME=$1
NAMESPACE="student-$STUDENT_NAME"
SERVICE_ACCOUNT="$STUDENT_NAME-sa"

echo "⚓ Generating fallback Kubeconfig for $STUDENT_NAME in namespace $NAMESPACE..."

# 1. Create Namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 2. Create ServiceAccount
kubectl create serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 3. Create RoleBinding giving admin access to their namespace
kubectl create rolebinding ${STUDENT_NAME}-admin \
  --clusterrole=admin \
  --serviceaccount=${NAMESPACE}:${SERVICE_ACCOUNT} \
  --namespace=${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Generate long-lived Token (Secret mapping) for K8s v1.24+
SECRET_NAME="${SERVICE_ACCOUNT}-token"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: $SERVICE_ACCOUNT
type: kubernetes.io/service-account-token
EOF

echo "Waiting for token to generate..."
sleep 2

TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 --decode)
# The kubeconfig handed to a student must point at an address THEIR VM can
# reach. `kubectl config view` often reports https://127.0.0.1:6443 (k3s) or
# https://0.0.0.0:6550 (k3d), which is useless off-host. Override as needed:
#   CLUSTER_SERVER=https://<reachable-ip>:6443 ./generate-student-kubeconfig.sh <name>
CLUSTER_SERVER="${CLUSTER_SERVER:-$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')}"
if [[ "$CLUSTER_SERVER" =~ (127\.0\.0\.1|0\.0\.0\.0|localhost) ]]; then
  echo "⚠️  CLUSTER_SERVER is '$CLUSTER_SERVER' — a student VM cannot reach a loopback address."
  echo "   Re-run with the cluster's reachable address:"
  echo "   CLUSTER_SERVER=https://<server-ip>:6443 $0 $STUDENT_NAME"
fi
CLUSTER_CA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

KUBECONFIG_FILE="kubeconfig-$STUDENT_NAME.yaml"

cat <<EOF > $KUBECONFIG_FILE
apiVersion: v1
kind: Config
clusters:
- name: admiral-cluster
  cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
contexts:
- name: ${STUDENT_NAME}-context
  context:
    cluster: admiral-cluster
    namespace: ${NAMESPACE}
    user: ${STUDENT_NAME}
current-context: ${STUDENT_NAME}-context
users:
- name: ${STUDENT_NAME}
  user:
    token: ${TOKEN}
EOF

echo "✅ Generated $KUBECONFIG_FILE successfully! Hand this file to the student."
