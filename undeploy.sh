#!/bin/bash
# Undeploy Todo App from Kubernetes

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="${ENVIRONMENT}-todo-app"

echo "========================================="
echo "Undeploying Todo App"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo ""

read -p "Are you sure you want to delete all resources in $NAMESPACE? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Deleting namespace and all resources..."
kubectl delete namespace "$NAMESPACE" --wait=true

echo ""
echo "========================================="
echo "Undeployment Complete!"
echo "========================================="
echo "All resources in $NAMESPACE have been deleted."
echo ""
