#!/bin/bash
# Deploy Todo App to Kubernetes

set -e

# Configuration
ENVIRONMENT=${1:-dev}
KUBECONFIG_PATH=${KUBECONFIG:-~/.kube/config}

echo "========================================="
echo "CloudBees Unify - Todo App Deployment"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Kubeconfig: $KUBECONFIG_PATH"
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|prod)$ ]]; then
    echo "Error: Invalid environment. Use: dev, qa, or prod"
    exit 1
fi

# Validate kubeconfig
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "Error: Kubeconfig not found at $KUBECONFIG_PATH"
    exit 1
fi

NAMESPACE="${ENVIRONMENT}-todo-app"
MANIFESTS_DIR="kubernetes/${ENVIRONMENT}"

echo "Deploying to namespace: $NAMESPACE"
echo ""

# Check if namespace exists, create if not
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Creating namespace: $NAMESPACE"
    kubectl apply -f "$MANIFESTS_DIR/namespace.yaml"
else
    echo "Namespace $NAMESPACE already exists"
fi

echo ""
echo "Applying Kubernetes manifests..."
echo ""

# Apply in order: secrets, configmaps, statefulsets, deployments, services, ingress
echo "1. Applying secrets..."
kubectl apply -f "$MANIFESTS_DIR/postgres-secret.yaml"

echo "2. Applying configmaps..."
kubectl apply -f "$MANIFESTS_DIR/backend-configmap.yaml"
kubectl apply -f "$MANIFESTS_DIR/frontend-configmap.yaml"

echo "3. Applying StatefulSet (PostgreSQL)..."
kubectl apply -f "$MANIFESTS_DIR/postgres-statefulset.yaml"

echo "4. Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n "$NAMESPACE" --timeout=300s

echo "5. Applying Deployments (Backend & Frontend)..."
kubectl apply -f "$MANIFESTS_DIR/backend-deployment.yaml"
kubectl apply -f "$MANIFESTS_DIR/frontend-deployment.yaml"

echo "6. Waiting for deployments to be ready..."
kubectl wait --for=condition=available deployment/backend -n "$NAMESPACE" --timeout=300s
kubectl wait --for=condition=available deployment/frontend -n "$NAMESPACE" --timeout=300s

echo "7. Applying Ingress..."
kubectl apply -f "$MANIFESTS_DIR/ingress.yaml"

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""

# Show status
echo "Pods:"
kubectl get pods -n "$NAMESPACE"
echo ""

echo "Services:"
kubectl get services -n "$NAMESPACE"
echo ""

echo "Ingress:"
kubectl get ingress -n "$NAMESPACE"
echo ""

echo "========================================="
echo "Deployment Summary"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo ""
echo "Access the application:"
if [ "$ENVIRONMENT" == "dev" ]; then
    echo "  URL: https://dev-todo.cloudbees-unify.example.com"
elif [ "$ENVIRONMENT" == "qa" ]; then
    echo "  URL: https://qa-todo.cloudbees-unify.example.com"
else
    echo "  URL: https://todo.cloudbees-unify.example.com"
fi
echo ""
echo "Check logs:"
echo "  kubectl logs -f deployment/backend -n $NAMESPACE"
echo "  kubectl logs -f deployment/frontend -n $NAMESPACE"
echo ""
echo "Delete deployment:"
echo "  ./undeploy.sh $ENVIRONMENT"
echo ""
