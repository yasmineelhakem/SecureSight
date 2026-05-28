# Terraform Infrastructure for SecureSight

## Overview

This directory contains Infrastructure as Code (IaC) for provisioning and managing AWS infrastructure for SecureSight. The infrastructure is built around **Amazon EKS (Elastic Kubernetes Service)** and includes complete networking, security, identity, and storage components.

### Architecture Highlights

- **Managed Kubernetes Cluster**: EKS cluster for container orchestration
- **Highly Available Networking**: Multi-AZ VPC with public and private subnets
- **Security-First Design**: Network policies, security groups, and IAM roles
- **Scalable Compute**: Auto-scaling node groups across availability zones
- **State Management**: Remote S3 backend with encryption and versioning
- **Secrets Management**: AWS Secrets Manager integration with external-secrets operator



## Remote State

The bootstrap step creates an S3 bucket to store the Terraform state file remotely, ensuring team collaboration and state consistency.

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

**What Gets Created:**
- S3 bucket for remote state storage
- Versioning enabled for state rollback capability
- Server-side encryption (AES256)
- Public access blocking for security


## Module Descriptions

### VPC Module
Creates the Virtual Private Cloud with:
- Single VPC with configurable CIDR block
- Internet and NAT gateways for connectivity
- DNS hostnames enabled

**Key Inputs:**
- `vpc_cidr`: CIDR block for VPC (default: `10.0.0.0/16`)
- `environment`: Environment name (dev/prod)

### Subnets Module
Manages subnet creation across multiple availability zones:
- Public subnets for load balancers and NAT gateways
- Private subnets for EKS nodes and applications
- Automatic tagging for Kubernetes service discovery

**Key Inputs:**
- `availability_zones`: List of AZs for multi-AZ setup
- `public_subnet_cidrs`: CIDR blocks for public subnets
- `private_subnet_cidrs`: CIDR blocks for private subnets

### Routes Module
Configures routing for network traffic:
- Routes from public subnets to Internet Gateway
- Routes from private subnets through NAT Gateway
- Enables secure outbound connectivity for private resources

### Security Groups Module
Creates network-level security controls:
- Node security group for EKS node communication
- Cluster security group for control plane
- Rules for pod-to-pod and ingress traffic

### IAM Module
Manages identity and access control:
- EKS cluster role for control plane
- Node group role for worker nodes
- Service-specific roles for add-ons

### IRSA Module (IAM Roles for Service Accounts)
Provides fine-grained IAM permissions to Kubernetes service accounts:
- EBS CSI driver role for volume management
- External Secrets Operator role for secrets access
- Follows least-privilege security principle

### EBS CSI Driver Module
Manages EBS volumes for Kubernetes persistent storage:
- Enables dynamic provisioning of EBS volumes
- Automatic attachment/detachment of volumes to pods

### Load Balancer Module
Configures AWS Load Balancing for Kubernetes:
- Integration with Kubernetes service type `LoadBalancer`

### Secrets Manager Module
Integrates AWS Secrets Manager with Kubernetes:
- Stores sensitive data outside of etcd
- Used by External Secrets Operator for automatic secret syncing


## Environments: Dev vs Prod

Having separate **dev** and **prod** environments allows you to:
- **Test safely**: Make changes in dev without affecting production
- **Different configurations**: Use smaller instances in dev for cost savings
- **Isolated databases**: Separate data for testing vs real users
- **Manage risk**: Deploy to prod with confidence after testing in dev

### Dev Environment

**Path:** `environments/dev/`

**Configuration** (`terraform.tfvars`):
```hcl
environment         = "dev"
vpc_cidr            = "10.0.0.0/16"
node_instance_type  = "t3.medium"    
node_desired_size   = 2              
node_max_size       = 4
```

**Use For:** Testing, development, non-critical workloads

### Prod Environment

**Path:** `environments/prod/`

**Configuration** (`terraform.tfvars`):
```hcl
environment         = "prod"
vpc_cidr            = "10.1.0.0/16"  
node_instance_type  = "t3.large"     
node_desired_size   = 3        
node_max_size       = 10      
```

**Use For:** Production applications, customer-facing services

## Deploy Development Environment

### Step 1: Navigate and Initialize

```bash
cd terraform/environments/dev

# Initialize Terraform with remote backend
terraform init
terraform plan
terraform apply -var-file=terraform.tfvars
```

**Output shows:**
- Cluster name and endpoint
- Security group IDs
- Node group IDs
- NAT gateway IDs


### Secrets Management 

#### `push_secrets.sh`

A bash script that securely stores database passwords and credentials in **AWS Secrets Manager** instead of hardcoding them. Your applications read secrets from AWS at runtime.

**Secrets pushed:**
- MongoDB credentials (carts database)
- MariaDB credentials (catalogue database)
- Redis password (session storage)
- RabbitMQ credentials (message broker)

### How to Execute

#### Step 1: Make Script Executable

```bash
cd terraform/environments/dev
chmod +x push_secrets.sh
```

#### Step 2: Export Secrets to Terminal

Open your terminal and export all required variables with your actual passwords:

```bash
export MONGO_USERNAME="carts"
export MONGO_PASSWORD="SecurePassword123"
...
```

**Verify exports worked:**
```bash
echo $MONGO_PASSWORD
# Output: SecurePassword123
```

#### Step 3: Run the Script

```bash
./push_secrets.sh dev
```

**Success Output:**
```
Pushing secrets for environment: dev
Region: us-east-2
Profile: default

Pushing dev/carts-db... ✅
Pushing dev/catalogue-db... ✅
Pushing dev/session-db... ✅
Pushing dev/rabbitmq... ✅

All secrets pushed successfully for 'dev'
```

### Verify Secrets in AWS

```bash
# List all stored secrets
aws secretsmanager list-secrets --region us-east-2

# View a specific secret value
aws secretsmanager get-secret-value --secret-id dev/carts-db --region us-east-2
```
