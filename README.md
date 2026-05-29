# Infrastructure (Kubernetes + Helm)

Kubernetes manifests and Helm charts for deploying the 2-tier to-do application.

## Overview

This repository contains:
- **Kubernetes manifests** for 3 environments (Dev, QA, Prod)
- **Helm chart** for templated deployments
- **Deployment scripts** for easy setup

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Namespace: {env}-todo-app                      │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐      ┌──────────────┐        │
│  │   Frontend   │      │   Backend    │        │
│  │  Deployment  │◄────►│  Deployment  │        │
│  │  (2 replicas)│      │  (2 replicas)│        │
│  └──────┬───────┘      └──────┬───────┘        │
│         │                      │                │
│         │                      │                │
│  ┌──────▼──────────────────────▼───────┐       │
│  │        PostgreSQL StatefulSet        │       │
│  │            (1 replica)                │       │
│  │       PersistentVolume (10Gi)        │       │
│  └──────────────────────────────────────┘       │
│                                                 │
│  ┌──────────────────────────────────────┐      │
│  │         Ingress (HTTPS)              │      │
│  │  /api → backend-service:5000         │      │
│  │  /    → frontend-service:5001        │      │
│  └──────────────────────────────────────┘      │
└─────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites
- Kubernetes cluster (GKE, EKS, AKS, or local)
- kubectl configured
- Docker images pushed to registry

### Deploy using Scripts

```bash
# Deploy to dev environment
./deploy.sh dev

# Deploy to QA
./deploy.sh qa

# Deploy to production
./deploy.sh prod
```

### Deploy using kubectl

```bash
# Deploy to dev
kubectl apply -f kubernetes/dev/

# Check status
kubectl get all -n dev-todo-app

# View logs
kubectl logs -f deployment/backend -n dev-todo-app
```

### Deploy using Helm

```bash
# Install dev environment
helm install todo-app-dev ./helm/todo-app \
  --namespace dev-todo-app \
  --create-namespace \
  --values helm/todo-app/values.yaml

# Upgrade
helm upgrade todo-app-dev ./helm/todo-app \
  --namespace dev-todo-app

# Uninstall
helm uninstall todo-app-dev -n dev-todo-app
```

## Environments

### Development (dev-todo-app)
- **Namespace**: dev-todo-app
- **URL**: https://dev-todo.cloudbees-unify.example.com
- **Replicas**: Backend (2), Frontend (2), PostgreSQL (1)
- **Purpose**: Active development and testing

### QA (qa-todo-app)
- **Namespace**: qa-todo-app
- **URL**: https://qa-todo.cloudbees-unify.example.com
- **Replicas**: Backend (2), Frontend (2), PostgreSQL (1)
- **Purpose**: Quality assurance and integration testing

### Production (prod-todo-app)
- **Namespace**: prod-todo-app
- **URL**: https://todo.cloudbees-unify.example.com
- **Replicas**: Backend (3), Frontend (3), PostgreSQL (1)
- **Purpose**: Production workloads

## Resources

### Backend Deployment
- **Image**: tejasdesai27/todo-backend:latest
- **Replicas**: 2 (dev/qa), 3 (prod)
- **CPU**: 100m request, 1000m limit
- **Memory**: 256Mi request, 1Gi limit
- **Port**: 5000
- **Health checks**: /health endpoint

### Frontend Deployment
- **Image**: tejasdesai27/todo-frontend:latest
- **Replicas**: 2 (dev/qa), 3 (prod)
- **CPU**: 100m request, 500m limit
- **Memory**: 128Mi request, 512Mi limit
- **Port**: 5001
- **Health checks**: /health endpoint

### PostgreSQL StatefulSet
- **Image**: postgres:15-alpine
- **Replicas**: 1
- **CPU**: 100m request, 500m limit
- **Memory**: 256Mi request, 512Mi limit
- **Storage**: 10Gi PersistentVolume
- **Port**: 5432

## Configuration

### Secrets (postgres-secret)
```yaml
POSTGRES_USER: todouser
POSTGRES_PASSWORD: todopass
POSTGRES_DB: todos
DATABASE_URL: postgresql://todouser:todopass@postgres-service:5432/todos
```

### Backend ConfigMap
```yaml
FLASK_ENV: development
SECRET_KEY: dev-secret-key-replace-in-production
```

### Frontend ConfigMap
```yaml
BACKEND_API_URL: http://backend-service:5000/api
SECRET_KEY: dev-secret-key-replace-in-production
FEATURE_DUE_DATE: "false"
FEATURE_DARK_MODE: "false"
```

## Deployment Order

1. **Namespace** - Create environment namespace
2. **Secrets** - Database credentials
3. **ConfigMaps** - Application configuration
4. **StatefulSet** - PostgreSQL with persistent storage
5. **Deployments** - Backend and Frontend
6. **Services** - ClusterIP services
7. **Ingress** - HTTPS routing

## Service Discovery

Services communicate via Kubernetes DNS:

```
backend → postgres-service:5432
frontend → backend-service:5000
ingress → frontend-service:5001
ingress → backend-service:5000
```

## Health Checks

### Liveness Probes
- Backend: GET /health (every 10s)
- Frontend: GET /health (every 10s)
- PostgreSQL: pg_isready (every 10s)

### Readiness Probes
- Backend: GET /health (every 5s)
- Frontend: GET /health (every 5s)
- PostgreSQL: pg_isready (every 5s)

## Scaling

### Manual Scaling
```bash
# Scale backend
kubectl scale deployment backend --replicas=5 -n dev-todo-app

# Scale frontend
kubectl scale deployment frontend --replicas=5 -n dev-todo-app
```

### Horizontal Pod Autoscaling
```bash
# Create HPA for backend
kubectl autoscale deployment backend \
  --cpu-percent=70 \
  --min=2 --max=10 \
  -n dev-todo-app
```

## Monitoring

### Get Pod Status
```bash
kubectl get pods -n dev-todo-app
kubectl describe pod <pod-name> -n dev-todo-app
```

### View Logs
```bash
# All backend logs
kubectl logs -f deployment/backend -n dev-todo-app

# Specific pod
kubectl logs -f <pod-name> -n dev-todo-app

# Previous container logs
kubectl logs <pod-name> --previous -n dev-todo-app
```

### Execute Commands
```bash
# Shell into backend pod
kubectl exec -it deployment/backend -n dev-todo-app -- /bin/sh

# Run psql in PostgreSQL
kubectl exec -it postgres-0 -n dev-todo-app -- psql -U todouser -d todos
```

## Troubleshooting

### Pod Not Starting
```bash
# Check events
kubectl describe pod <pod-name> -n dev-todo-app

# Check logs
kubectl logs <pod-name> -n dev-todo-app
```

### Database Connection Issues
```bash
# Check PostgreSQL is running
kubectl get pods -l app=postgres -n dev-todo-app

# Test connection
kubectl exec -it deployment/backend -n dev-todo-app -- \
  python -c "import psycopg2; psycopg2.connect('postgresql://todouser:todopass@postgres-service:5432/todos')"
```

### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n dev-todo-app

# Port forward for testing
kubectl port-forward service/backend-service 5000:5000 -n dev-todo-app
```

## Cleanup

### Delete Specific Environment
```bash
./undeploy.sh dev
```

### Manual Cleanup
```bash
kubectl delete namespace dev-todo-app
```

## CloudBees Unify Integration

This infrastructure integrates with:
- ✅ Release Orchestration (automated deployment)
- ✅ Multi-environment promotion (Dev → QA → Prod)
- ✅ Evidence collection (deployment artifacts)
- ✅ Approval gates (manual QA/Prod approvals)

Part of CloudBees Unify Reference Architecture project.

**Team**: Tejas Desai (2-tier), Dinesh Narlakanti (3-tier), Anudeep Nalla (Infrastructure)
**Lead**: Xhesi Galanxhi
