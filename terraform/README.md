# SecureSight: AWS Infrastructure

> Kubernetes infrastructure on AWS EKS built with Terraform.
> Designed around security, cost-efficiency, and high availability.

## Table of Contents

- [Infrastructure Overview](#infrastructure-overview)
- [Bootstrap: Provision S3 State Backend](#bootstrap--provision-s3-state-backend)
- [Modules](#modules)
  - [VPC](#1-vpc-module)
  - [Subnets](#2-subnets-module)
  - [Routes](#3-routes-module)
  - [Security Groups](#4-security-groups-module)
  - [IAM](#5-iam-module)
  - [IRSA](#6-irsa-module)
  - [EKS](#7-eks-module)
  - [Load Balancer](#8-load-balancer-module)
  - [EBS CSI Driver](#9-ebs-csi-driver-module)
  - [Secrets Manager](#10-secrets-manager-module)
- [Environments: Dev vs Prod](#environments--dev-vs-prod)
- [Deployment Guide](#deployment-guide)
- [Secrets Management](#secrets-management)


## Infrastructure Overview

The infrastructure is built around a **private EKS cluster** inside a VPC. Nothing runs directly on the internet: all workloads live in private subnets and are only reachable through the Load Balancer.


**Inbound traffic:** User → IGW → ALB (public subnet) → EKS Node (private subnet) → Pod

**Outbound traffic:** Pod → NAT Gateway → IGW → Internet (for pulling images, calling AWS APIs)



## Bootstrap: Provision S3 State Backend

Before any environment can be deployed, Terraform needs a place to store its **state file**, a record of every resource it manages.

### Why S3 for State

Storing state locally means only one person can work on the infrastructure and the state is lost if the machine dies. S3 solves both problems, state is shared across the team, versioned for recovery, and locked to prevent two people applying at the same time.

### Why Bootstrap is a Separate Folder

This is the classic chicken-and-egg problem: Terraform needs S3 to store state, but to create S3 it needs state somewhere, which doesn't exist yet. The solution is two phases: run with local state first to create the bucket, then add the S3 backend config and migrate. The `bootstrap/` folder handles this in isolation so it never interferes with environment deployments.

### What Bootstrap Creates

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` | Stores all Terraform state files |
| `aws_s3_bucket_versioning` | Enables state rollback to any previous version |
| `aws_s3_bucket_server_side_encryption_configuration` | AES256 encryption at rest |
| `aws_s3_bucket_public_access_block` | Fully private, no public access possible |

After bootstrap, each environment points to this bucket with a unique key so dev and prod state are completely isolated: `securesight/dev/terraform.tfstate` and `securesight/prod/terraform.tfstate`.

### How to Run

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

---

## Modules

Every module follows the same 3-file structure: `main.tf` for resources, `variables.tf` for inputs, and `outputs.tf` for values exposed to other modules.

---

### 1. VPC Module

Creates the private network boundary that isolates the entire infrastructure. Everything subnets, nodes, load balancers lives inside this VPC. Nothing enters or exits without explicit permission.

**Resources Created**

| Resource | Purpose |
|---|---|
| `aws_vpc` | Isolated network with CIDR `10.0.0.0/16` (65,536 IPs) |
| `aws_internet_gateway` | Single door between VPC and internet |

DNS hostnames and DNS support are both enabled, required for EKS node registration and Kubernetes internal service discovery between pods.

**Outputs:** `vpc_id` and `internet_gateway_id` used by every other module.

---

### 2. Subnets Module

Divides the VPC into public and private zones across 2 availability zones and creates the NAT Gateway so private nodes can reach the internet without being reachable from it.

**Resources Created**

| Resource | Purpose |
|---|---|
| `aws_subnet` public ×2 | Hosts ALB and NAT Gateway has direct internet route |
| `aws_subnet` private ×2 | Hosts EKS nodes no direct internet route |
| `aws_eip` | Fixed public IP address for the NAT Gateway |
| `aws_nat_gateway` | Outbound-only internet access for private subnets |

Using 2 availability zones means if one AZ has a hardware failure, nodes and the ALB in the second AZ keep the application running.

EKS requires specific tags on subnets to auto-discover where to place load balancers. Public subnets are tagged with `kubernetes.io/role/elb` for public-facing load balancers, and private subnets with `kubernetes.io/role/internal-elb` for internal ones. Without these tags, EKS cannot provision load balancers correctly.

**Outputs:** `public_subnet_ids` → lb module, `private_subnet_ids` → eks module, `nat_gateway_id` → routes module.

---

### 3. Routes Module

Tells traffic where to go. Without route tables, subnets are isolated, the IGW and NAT Gateway exist but nothing knows to use them.

**Resources Created**

| Resource | Purpose |
|---|---|
| `aws_route_table` public | Routes public subnet traffic to IGW |
| `aws_route_table` private | Routes private subnet traffic through NAT |
| `aws_route` ×2 | The actual `0.0.0.0/0` routing rules |
| `aws_route_table_association` ×4 | Links each subnet to its route table |

Public subnet nodes route directly to the IGW and reach the internet with responses coming back the same way. Private subnet nodes route through NAT which forwards to the IGW, the internet can never initiate a connection back into the private subnet.

---

### 4. Security Groups Module

Per-resource stateful firewalls that enforce exactly what traffic is allowed between layers. Three security groups protect three different layers of the stack.

All rules use `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` as separate resources.
**`sg_lb` Load Balancer**

| Direction | Port | Source | Reason |
|---|---|---|---|
| Inbound | 80, 443 | Internet | Accept HTTP/HTTPS from users |
| Outbound | all | EKS nodes | Forward requests to pods |

**`sg_eks_nodes` Worker Nodes**

| Direction | Port | Source | Reason |
|---|---|---|---|
| Inbound | all | `sg_lb` | Only accept traffic from ALB, not raw internet |
| Inbound | all | self | Node-to-node Kubernetes pod traffic |
| Outbound | all | Internet | Pull images, call AWS APIs via NAT |


The internet can only reach the ALB and the ALB can only reach nodes.

---

### 5. IAM Module

Grants AWS services the permissions they need to operate on your behalf. Every role follows least privilege: only the policies absolutely required.

**EKS Cluster Role** assumed by `eks.amazonaws.com`

Attaches `AmazonEKSClusterPolicy` which lets the EKS service manage EC2, networking, and autoscaling on your behalf.

**EKS Node Role** assumed by `ec2.amazonaws.com` (the worker nodes themselves)

| Policy | Why |
|---|---|
| `AmazonEKSWorkerNodePolicy` | Nodes can register and join the cluster |
| `AmazonEC2ContainerRegistryReadOnly` | Nodes can pull container images from ECR |
| `AmazonEKS_CNI_Policy` | Configures pod-level networking via the VPC CNI plugin |

**Outputs:** `eks_cluster_role_arn` and `eks_node_role_arn` → eks module, `eks_node_role_name` → irsa module.

---

### 6. IRSA Module

IRSA (IAM Roles for Service Accounts) gives individual Kubernetes pods their own scoped AWS IAM permissions, without granting broad permissions to the entire node.

Without IRSA, the node role holds all permissions and any pod on that node inherits them, one compromised pod means full node-level AWS access. With IRSA, the EBS CSI pod can only manage EBS volumes, the External Secrets pod can only read secrets, and all other pods have zero AWS access.

This works because EKS creates an OIDC provider that allows Kubernetes service accounts to assume IAM roles via `sts:AssumeRoleWithWebIdentity`, scoped to a specific namespace and service account name.

**EBS CSI Driver Role**
- Service account: `kube-system/ebs-csi-controller-sa`
- Policy: `AmazonEBSCSIDriverPolicy`: allows dynamic EBS volume provisioning only

**External Secrets Operator Role**
- Service account: `sock-shop/external-secrets-sa`
- Custom policy: `secretsmanager:GetSecretValue` and `secretsmanager:DescribeSecret` scoped to environment-specific secrets only

**Outputs:** `ebs_csi_driver_role_arn` → ebs-csi-driver module, `external_secrets_role_arn` → referenced in Kubernetes manifests.

---

### 7. EKS Module

Creates the Kubernetes cluster. EKS has two distinct parts: the control plane managed entirely by AWS, and the node group which are EC2 instances you own and pay for.

**Resources Created**

| Resource | Purpose |
|---|---|
| `aws_eks_cluster` | Control plane: AWS managed API server, scheduler, etcd |
| `aws_eks_node_group` | Worker nodes: EC2 t3.medium running your application pods |
| `aws_iam_openid_connect_provider` | OIDC provider enabling IRSA for pod-level IAM roles |

AWS runs and maintains the control plane servers. The node group is EC2 instances in the private subnets that actually run the pods. The node group auto-scales between a minimum of 1 and maximum of 4 nodes, with 2 running under normal load.

**Outputs:** `cluster_name`, `oidc_provider_arn`, `oidc_provider_url` → irsa and ebs-csi-driver modules.

---

### 8. Load Balancer Module

Creates the Application Load Balancer: the single public entry point that receives all incoming user traffic and distributes it across healthy EKS nodes. If a node or pod fails health checks, the ALB stops routing to it automatically.

**Resources Created**

| Resource | Purpose |
|---|---|
| `aws_lb` | Internet-facing ALB in public subnets |
| `aws_lb_target_group` | Targets pod IPs directly (`target_type = "ip"`) |
| `aws_lb_listener` HTTP | Port 80, behavior differs per environment |
| `aws_lb_listener` HTTPS | Port 443, prod only, requires ACM certificate |

In dev, the HTTP listener forwards directly to pods, no certificate needed for faster iteration. In prod, HTTP redirects permanently to HTTPS and a valid ACM certificate is required. Deletion protection is also enabled in prod to prevent accidental destruction.

---

### 9. EBS CSI Driver Module

Installs the AWS EBS CSI (Container Storage Interface) driver as a managed EKS addon. This enables Kubernetes pods to dynamically create, attach, and manage EBS volumes as persistent storage, without any manual AWS console work.

Without this addon, any pod requesting a PersistentVolumeClaim gets no response, databases cannot persist data across pod restarts. With it installed, the driver calls the AWS API using its IRSA role, creates an EBS volume in the same AZ as the pod, and attaches it automatically.

**Resource Created:** `aws_eks_addon` — installs `aws-ebs-csi-driver` directly into the cluster, authenticated via the IRSA role from the irsa module.

---

### 10. Secrets Manager Module

Creates secret containers in AWS Secrets Manager for every service that needs credentials. Terraform creates the **structure and metadata only**, actual credential values are pushed separately via CLI and never appear in Terraform code, variables, or state.

**Secrets Created**

| Secret Path | Service | Purpose |
|---|---|---|
| `{env}/carts-db` | MongoDB | Carts service database credentials |
| `{env}/catalogue-db` | MariaDB | Catalogue service database credentials |
| `{env}/session-db` | Redis | Session storage password |
| `{env}/rabbitmq` | RabbitMQ | Message broker credentials |

If Terraform managed the actual values, credentials would flow from variables into the state file stored in S3, anyone with S3 read access could read your passwords. By keeping Terraform responsible only for the secret structure, the state file contains ARNs only and credentials never touch Terraform at all.

Every secret version has `lifecycle { ignore_changes = [secret_string] }`, this tells Terraform not to overwrite credentials on the next `terraform apply`. Without this block, every apply would reset secrets back to empty strings.

---

## Environments — Dev vs Prod

Both environments use the exact same modules. Only the values in `terraform.tfvars` differ.

| Setting | Dev | Prod |
|---|---|---|
| `node_instance_type` | t3.medium | t3.large |
| `node_desired_size` | 2 | 3 |
| `node_min_size` | 1 | 2 |
| `node_max_size` | 4 | 10 |
| `vpc_cidr` | 10.0.0.0/16 | 10.1.0.0/16 |
| `certificate_arn` | null | arn:aws:acm:... |
| ALB HTTP listener | forward to pods | redirect to HTTPS |
| ALB HTTPS listener | disabled | enabled |
| `deletion_protection` | false | true |
| Secret recovery window | 0 days | 30 days |

---

## Deployment Guide

**Prerequisites:** Terraform >= 1.10, AWS CLI >= 2.0, kubectl >= 1.31

**Step 1: Authenticate**

Login with AWS SSO and export your profile and region as environment variables so Terraform picks them up automatically without hardcoding them in any file.
```bash
aws configure sso 
export AWS_PROFILE='the_profile'
```

**Step 2: Bootstrap**

```bash
cd terraform/bootstrap
terraform init 
terraform plan
terraform apply
```

**Step 3: Deploy dev**

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

After apply, connect kubectl with:

```bash
aws eks update-kubeconfig --region us-east-2 --name securesight-eks-dev
kubectl get nodes
```

---

## Secrets Management

After `terraform apply` creates the empty secret containers, push actual credentials directly to AWS using the provided script. Credentials are exported as shell environment variables (memory only, never written to disk), the script pushes them via AWS CLI directly to Secrets Manager, and they are unset from the shell when done.

```bash
export MONGO_PASSWORD="..."
export REDIS_PASSWORD="..."
# export all required credentials...

./push-secrets.sh dev
```

The External Secrets Operator running in the cluster then reads these secrets using its IRSA role and injects them automatically into pods as Kubernetes secrets, the application reads them as environment variables at runtime.

