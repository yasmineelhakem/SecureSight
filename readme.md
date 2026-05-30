# SecureSight: Production-Grade Kubernetes on AWS EKS

> Taking the Sock Shop microservices demo and hardening it for real-world deployment on AWS EKS
> with production-ready Kubernetes manifests, cloud infrastructure as code, and runtime security.

---

## What This Project Is

[Sock Shop](https://github.com/ocp-power-demos/sock-shop-demo) is a well-known cloud-native demo application built around a distributed microservices architecture. It is intentionally simple: great for learning, not ready for production.

This project takes that foundation and progressively hardens it across three areas:

- **Infrastructure**: AWS EKS cluster provisioned with Terraform (VPC, networking, security, IAM, secrets)
- **Kubernetes Manifests**: production improvements applied with Kustomize (stateful workloads, autoscaling, security policies, secrets management, ingress)
- **Runtime Security**: Tetragon policies for eBPF-based threat detection and enforcement


## Infrastructure

The cloud infrastructure is provisioned with Terraform on AWS EKS in `us-east-2`. It follows a security-first, cost-efficient design: all workloads run in private subnets, only the load balancer is public-facing, and credentials never appear in code or state.

For the full infrastructure breakdown, modules, architecture diagram, deployment guide, and secrets management see the **[Terraform README](./terraform/README.md)**.


## Kubernetes Manifests

Manifests are structured with **Kustomize** using a shared base and two environment overlays.

### Dev Overlay: validated on Minikube

| Improvement | What Was Done |
|---|---|
| ConfigMaps & Secrets | Extracted hardcoded env vars from Deployment specs into dedicated resources |
| StatefulSets | Migrated all database workloads from Deployments for stable identity and per-pod storage |
| Persistent Volumes | Replaced `emptyDir` with PersistentVolumeClaims so data survives pod restarts |
| Horizontal Pod Autoscaler | Added HPAs for all stateless services, tuned per workload type |
| Network Policies | Default-deny strategy with explicit allowlists per service. |
| RBAC | Dedicated ServiceAccounts, Roles, and RoleBindings per microservice, least privilege |

### Prod Overlay: deployed on AWS EKS

| Improvement | What Was Done |
|---|---|
| EBS Storage (gp3) | StorageClass using AWS EBS CSI driver for dynamic volume provisioning |
| StatefulSet Patches | All database StatefulSets patched to use the `gp3` StorageClass via Kustomize |
| External Secrets | External Secrets Operator pulls credentials from AWS Secrets Manager via IRSA, replaces plain Kubernetes Secrets |
| AWS ALB Ingress | Path-based routing through an Application Load Balancer, single secure public endpoint replacing NodePort |

For the full write-up on every decision and implementation detail, read the **[Medium article](https://medium.com/@yasmineelhakem8/from-demo-to-production-improving-kubernetes-manifests-in-the-sock-shop-microservices-application-d23f92a49f7e)**.


## Runtime Security

Tetragon policies provide eBPF-based threat detection and enforcement at the kernel level, catching malicious behavior that Kubernetes-layer controls cannot see.

For the full Tetragon setup and policy explanations, see the **[Tetragon README](./tetragon/readme.md)** or  **full article:** [Runtime Security on Kubernetes with Tetragon & eBPF](https://medium.com/@yasmineelhakem8/runtime-security-on-kubernetes-with-tetragon-ebpf-aad6dde34a43)
 
---

## Tech Stack

`Kubernetes` · `Kustomize` · `AWS EKS` · `AWS EBS (gp3)` · `AWS ALB` · `AWS Secrets Manager` · `External Secrets Operator` · `Terraform` · `Tetragon` · `Minikube`