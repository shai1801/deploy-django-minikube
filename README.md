# deploy-django-minikube

A Django application (Polls) containerised with Docker and deployed on a local Kubernetes cluster via Minikube.

---

## Project structure

```
.
├── app/                      # Django project
│   ├── manage.py
│   ├── mysite/               # Project settings, urls, wsgi
│   └── polls/                # Polls application (models, views, templates)
├── k8s/                      # Kubernetes manifests
│   ├── configmap.yaml        # Non-secret environment variables
│   ├── postgres-secret.yaml  # Database credentials (base64-encoded)
│   ├── postgres-pvc.yaml     # PersistentVolumeClaim for PostgreSQL
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   ├── deployment.yaml       # Django Deployment (2 replicas)
│   ├── service.yaml          # NodePort Service (port 30080)
│   └── ingress.yaml          # Optional Ingress for django.local
├── Dockerfile
├── entrypoint.sh
└── requirements.txt
```

---

## Prerequisites

| Tool | Tested version |
|------|----------------|
| [Docker](https://docs.docker.com/get-docker/) | 24+ |
| [Minikube](https://minikube.sigs.k8s.io/docs/start/) | 1.32+ |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.28+ |

---

## Quick start

### 1 — Start Minikube

```bash
minikube start
```

### 2 — Point your shell at Minikube's Docker daemon

Build the image directly inside Minikube so that `imagePullPolicy: Never` works.

```bash
eval $(minikube docker-env)
```

### 3 — Build the Docker image

```bash
docker build -t django-app:latest .
```

### 4 — Deploy to Kubernetes

```bash
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Or apply everything at once:

```bash
kubectl apply -f k8s/
```

### 5 — Wait for pods to become ready

```bash
kubectl get pods -w
```

### 6 — Access the application

```bash
minikube service django --url
# e.g. http://192.168.49.2:30080
```

Open the URL in your browser and append `/polls/` to reach the Polls app.

---

## Optional: Ingress

To use the Ingress resource (requires the NGINX ingress addon):

```bash
minikube addons enable ingress
kubectl apply -f k8s/ingress.yaml
```

Add the following entry to `/etc/hosts`:

```
$(minikube ip)   django.local
```

Then visit `http://django.local/polls/`.

---

## Creating a superuser (Django admin)

```bash
kubectl exec -it deployment/django -- python manage.py createsuperuser
```

---

## Teardown

```bash
kubectl delete -f k8s/
minikube stop
```

---

## Environment variables

| Variable | Source | Default | Description |
|----------|--------|---------|-------------|
| `DJANGO_SECRET_KEY` | Secret (recommended) | hard-coded fallback | Django secret key |
| `DJANGO_DEBUG` | ConfigMap | `False` | Enable debug mode |
| `DJANGO_ALLOWED_HOSTS` | ConfigMap | `*` | Comma-separated allowed hosts |
| `DB_NAME` | ConfigMap / Secret | `djangodb` | PostgreSQL database name |
| `DB_USER` | ConfigMap / Secret | `djangouser` | PostgreSQL user |
| `DB_PASSWORD` | Secret | `djangopassword` | PostgreSQL password |
| `DB_HOST` | ConfigMap | `postgres` | PostgreSQL service hostname |
| `DB_PORT` | ConfigMap | `5432` | PostgreSQL port |

> **Security note:** The `postgres-secret.yaml` file contains default base64-encoded credentials for local development only. Replace these values before deploying to any shared or production environment.
