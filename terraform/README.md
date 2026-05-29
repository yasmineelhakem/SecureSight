# Terraform Infrastructure for SecureSight

## Overview

This directory contains Infrastructure as Code (IaC) for provisioning and managing AWS infrastructure for SecureSight. The infrastructure is built around **Amazon EKS (Elastic Kubernetes Service)** and includes complete networking, security, identity, and storage components.

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


## Terraform Infrastructure Modules

## 1. VPC Module

Creates the main AWS VPC and attaches an Internet Gateway for public internet access.

### Resources Created
- AWS VPC
- Internet Gateway (IGW)

### Features
- Configurable CIDR block
- DNS support and DNS hostname configuration
- Environment-based naming convention
- Custom tagging support
- Internet connectivity through IGW


## 2. Subnets Module

Creates public and private subnets across multiple Availability Zones and provisions a NAT Gateway for outbound internet access from private subnets.

### Resources Created
- Public Subnets
- Private Subnets
- Elastic IP (EIP)
- NAT Gateway

### Features
- Multi-AZ subnet deployment
- Automatic public IP assignment for public subnets
- Kubernetes-compatible subnet tagging
- NAT Gateway for outbound internet access from private subnets
- Environment and custom tagging support

### Kubernetes Integration
The module adds subnet tags required by Amazon EKS:
- Public subnets for external Load Balancers (`kubernetes.io/role/elb`)
- Private subnets for internal Load Balancers (`kubernetes.io/role/internal-elb`)

## 3. Routes Module

Creates route tables and associates them with public and private subnets.

### Resources Created
- Public Route Table
- Private Route Table
- Internet Route
- NAT Gateway Route
- Route Table Associations

### Features
- Public subnet routing through the Internet Gateway
- Private subnet routing through the NAT Gateway
- Automatic subnet-to-route-table associations
- Separation between public and private traffic

### Traffic Flow
- Public Subnets → Internet Gateway → Internet
- Private Subnets → NAT Gateway → Internet


## 4. Security Groups Module

Creates security groups for the Application Load Balancer and EKS worker nodes.

### Resources Created
- Load Balancer Security Group
- EKS Nodes Security Group
- Ingress and Egress Rules

### Features
#### Load Balancer Security Group
- Allows inbound HTTP traffic on port 80
- Allows inbound HTTPS traffic on port 443
- Allows outbound traffic to EKS nodes

#### EKS Nodes Security Group
- Allows inbound traffic from the Load Balancer
- Allows node-to-node communication
- Allows outbound internet access

### Purpose
Provides secure communication between:
- Internet users
- Application Load Balancer
- EKS worker nodes


## 5. IAM Module

Creates IAM roles and policy attachments required for the EKS cluster and worker nodes.

### EKS Cluster IAM Role

### Resources Created
- EKS Cluster IAM Role
- AmazonEKSClusterPolicy attachment

### Features
- Allows Amazon EKS control plane management
- Grants required permissions for cluster operations


### EKS Node IAM Role

#### Resources Created
- EKS Worker Node IAM Role
- AmazonEKSWorkerNodePolicy attachment
- AmazonEC2ContainerRegistryReadOnly attachment
- AmazonEKS_CNI_Policy attachment

#### Features
- Allows worker nodes to join the cluster
- Grants permissions to pull images from Amazon ECR
- Enables Kubernetes networking through the EKS CNI plugin


## 6. EKS Module

Creates the Amazon EKS cluster, managed node group, and OIDC provider.

### Resources Created
- EKS Cluster
- Managed Node Group
- IAM OIDC Provider

### Features
- Deploys Kubernetes control plane
- Creates managed worker nodes in private subnets
- Configurable Kubernetes version
- Configurable node scaling settings
- OIDC provider support for IRSA
- Multi-subnet cluster networking

### Node Group Configuration
- Managed node groups
- Configurable instance types
- Auto scaling support
- Rolling update configuration
- Worker nodes deployed in private subnets

### OIDC Integration
Creates an IAM OpenID Connect provider used for IAM Roles for Service Accounts (IRSA).

## 7. IRSA Module

Creates IAM Roles for Service Accounts (IRSA) used by Kubernetes controllers and operators.


### EBS CSI Driver IRSA

Creates an IAM role for the Amazon EBS CSI Driver.

#### Resources Created
- IAM Role for EBS CSI Driver
- AmazonEBSCSIDriverPolicy attachment

#### Features
- Allows Kubernetes to dynamically provision EBS volumes
- Uses IAM Roles for Service Accounts (IRSA)
- Restricts access to the EBS CSI controller service account

#### Kubernetes Service Account
- `kube-system/ebs-csi-controller-sa`


### External Secrets IRSA

Creates an IAM role and policy for the External Secrets Operator.

### Resources Created
- IAM Role for External Secrets
- Custom IAM Policy for AWS Secrets Manager access

### Features
- Allows Kubernetes applications to retrieve secrets from AWS Secrets Manager
- Uses IAM Roles for Service Accounts (IRSA)
- Restricts access to environment-specific secrets

### Permissions
- `secretsmanager:GetSecretValue`
- `secretsmanager:DescribeSecret`

### Kubernetes Service Account
- `sock-shop/external-secrets-sa`


## 8. Load Balancer Module

Creates an Application Load Balancer (ALB), target group, and listeners.

### Resources Created
- Application Load Balancer (ALB)
- Target Group
- HTTP Listener
- HTTPS Listener

### Features
- Internet-facing Application Load Balancer
- Environment-specific listener configuration
- HTTP to HTTPS redirection in production
- TLS termination support
- Target group forwarding to Kubernetes services

### Environment Behavior

#### Development
- HTTP listener enabled

#### Production
- HTTP listener redirects to HTTPS
- HTTPS listener enabled using ACM certificate
- Deletion protection enabled


## 9. Secrets Manager Module

Creates AWS Secrets Manager secrets for application services.

### Resources Created
- MongoDB Secret
- MariaDB Secret
- Redis Secret
- RabbitMQ Secret

### Features
- Centralized secret management
- Environment-specific secret naming
- Secret version management
- Secure integration with External Secrets Operator

### Managed Secrets

- Carts Service : MongoDB credentials
- Catalogue Service : MariaDB credentials
- Session Service : Redis password
- RabbitMQ : Broker credentials

<hr>

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

#### Step 4: Verify Secrets in AWS

```bash
# List all stored secrets
aws secretsmanager list-secrets --region us-east-2

# View a specific secret value
aws secretsmanager get-secret-value --secret-id dev/carts-db --region us-east-2
```
