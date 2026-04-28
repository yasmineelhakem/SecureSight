# From Demo to Production: Improving Kubernetes Manifests in the Sock Shop Microservices Application

> 📖 Full write-up on Medium: [From Demo to Production](https://medium.com/@yasmineelhakem8/from-demo-to-production-improving-kubernetes-manifests-in-the-sock-shop-microservices-application-d23f92a49f7e)

## Overview

This project takes the [Sock Shop](https://github.com/ocp-power-demos/sock-shop-demo) — a cloud-native demo application showcasing a distributed microservices architecture on Kubernetes — and progressively hardens it for real-world deployment on **AWS (EKS)**.

The manifests are organized with **Kustomize**, using a shared base and two environment-specific overlays:
- **Dev overlay** — validated locally on Minikube
- **Prod overlay** — designed for AWS EKS deployment

---

## Improvements Applied

### Dev Overlay

| Step | Improvement |
|------|-------------|
| **1. ConfigMaps & Secrets** | Extracted hardcoded env vars (DB hostnames, ports, credentials) from Deployment specs into dedicated `ConfigMap` and `Secret` resources |
| **2. Deployments → StatefulSets** | Migrated all database workloads (`orders-db`, `catalogue-db`, `carts-db`, `user-db`, `session-db`, `rabbitmq`) to `StatefulSets` for stable pod identity, stable DNS, and per-pod storage |
| **3. Persistent Volumes** | Replaced `emptyDir` volumes with `PersistentVolumeClaims` to ensure data survives pod restarts |
| **4. Horizontal Pod Autoscaler (HPA)** | Added HPAs for all stateless services, tuned per service (CPU-bound, memory-bound, or lightweight) with proper resource requests |
| **5. Network Policies** | Implemented a default-deny strategy (ingress + egress), with explicit allowlists per service — limiting blast radius in case of compromise |
| **6. RBAC** | Assigned dedicated `ServiceAccounts`, `Roles`, and `RoleBindings` to each microservice, following the principle of least privilege |

### Prod Overlay

| Step | Improvement |
|------|-------------|
| **1. AWS EBS Storage (gp3)** | Defined a `StorageClass` using the AWS EBS CSI driver for dynamic volume provisioning |
| **2. StatefulSet Storage Patches** | Patched all database StatefulSets to use the `gp3` StorageClass via Kustomize patches |
| **3. External Secrets** | Integrated **External Secrets Operator** to pull sensitive credentials from **AWS Secrets Manager** via IRSA, replacing plain Kubernetes Secrets |
| **4. AWS ALB Ingress** | Configured path-based routing through an **AWS Application Load Balancer**, replacing NodePort exposure with a single secure public endpoint |

---

## Deployment (EKS)

```bash
# Connect to the EKS cluster
aws eks update-kubeconfig --region us-east-2 --name eks-dev

# Apply the production overlay
kubectl apply -k manifests/overlays/prod
```

**Prerequisites installed via Helm/official guides:**
- AWS Load Balancer Controller
- External Secrets Operator
- Metrics Server

---

## Tech Stack

`Kubernetes` · `Kustomize` · `AWS EKS` · `AWS EBS (gp3)` · `AWS ALB` · `AWS Secrets Manager` · `External Secrets Operator` · `Terraform` · `Minikube`