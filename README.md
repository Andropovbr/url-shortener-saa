# URL Shortener — AWS Architecture Study Project

## Overview

This project simulates a production-grade URL shortener architecture built on AWS using Terraform.

The primary goal is to practice AWS Solutions Architect Associate (SAA-C03) concepts through hands-on infrastructure design, focusing on:

- High availability (Multi-AZ)
- Scalability
- Security best practices
- Infrastructure as Code
- Cost awareness
- Architectural trade-offs

---

## Project Status

Current progress:

- Milestone 1 — Infrastructure bootstrap
- Milestone 2 — Core networking
- Milestone 3 — Compute layer (ECS + ALB)
- Milestone 4 — Data layer (DynamoDB)
- Milestone 5 — Observability & Security
- Milestone 6 — Cache layer (ElastiCache / Valkey)
- Milestone 7 — Cost & Architecture Review

Upcoming milestones:

- CI/CD pipeline for application deployment
- CI/CD pipeline for Terraform
- Terraform refactoring and modularization

---

## Project Philosophy

Terraform infrastructure code in this repository is written manually to reinforce understanding of AWS architecture and infrastructure design.

The purpose is to gain hands-on experience with:

- Resource dependencies
- Networking architecture
- IAM scoping
- Service interactions
- Architectural trade-offs

AI may be used for architectural discussion and reasoning, but infrastructure code is implemented manually.

---

## Architecture Overview

### Request Flow

Client  
↓  
AWS WAF  
↓  
Application Load Balancer  
↓  
ECS Fargate Service (FastAPI application)  
↓  
Cache layer (ElastiCache - cache-aside pattern)  
↓  
DynamoDB (source of truth)

---

### Core Components

- ECS Fargate (FastAPI application)
- Application Load Balancer (Multi-AZ)
- AWS WAF protecting public entrypoint
- DynamoDB (on-demand, TTL enabled)
- ElastiCache (Valkey) as cache layer
- CloudWatch Logs and Alarms
- VPC Endpoints:
  - Gateway Endpoint for DynamoDB
  - Interface Endpoint for Secrets Manager

---

## Architecture Goals

The system is designed to include:

- Multi-AZ VPC architecture
- Application Load Balancer
- ECS Fargate service
- DynamoDB data layer
- ElastiCache cache layer
- CloudWatch Logs and Alarms for observability
- AWS WAF for edge protection
- Security best practices
- Infrastructure as Code with Terraform
- Cost-conscious design (no NAT Gateway)

Infrastructure is destroyed after each study session to avoid unnecessary AWS charges.

---

## Architecture Decisions

### No NAT Gateway

The architecture avoids the use of a NAT Gateway to reduce costs.

Instead, VPC Endpoints are used to access AWS services privately.

---

### Cache Strategy

A cache-aside pattern is implemented using ElastiCache (Valkey):

1. Application checks Redis
2. On cache miss, queries DynamoDB
3. Stores result in Redis with TTL
4. Returns response

This improves read performance and reduces load on DynamoDB.

---

### ElastiCache High Availability Trade-off

The current implementation uses a single-node cache to minimize cost.

The network is designed with multiple data subnets, allowing future expansion to a highly available Redis replication group.

---

### Environment Isolation

Separate VPCs are used for dev and prod environments to ensure isolation and allow independent evolution.

---

## Cost Considerations

This project is designed with cost-awareness in mind:

- No NAT Gateway (major cost reduction)
- DynamoDB on-demand pricing
- Minimal ECS task sizing (256 CPU / 512 MB)
- Single-node ElastiCache instance
- Infrastructure destroyed after each lab session

### Main cost drivers

- Application Load Balancer
- VPC (data processing and endpoints)
- ElastiCache

---

## Naming Convention

Pattern:

<project>-<component>-<environment>

Project:

url-shortener-saa

Environments:

dev  
prod

Example:

url-shortener-saa-vpc-dev

---

## Tagging Standard

All AWS resources must include the following tags:

| Key | Example Value |
|-----|---------------|
| Project | url-shortener-saa |
| Owner | Andre Santos |
| Environment | dev or prod |
| ManagedBy | Terraform |

---

## Repository Structure

infra/  
  bootstrap/   # Terraform backend resources (S3 + DynamoDB)  
  core/        # Foundational infrastructure (VPC, subnets, base SGs)  
  runtime/     # Application infrastructure (ALB, ECS, DynamoDB, WAF, etc.)

app/           # Application source code  
diagrams/      # Architecture diagrams  
docs/          # Architectural decisions and notes  

---

## Infrastructure Separation Strategy

### bootstrap

Contains only Terraform backend infrastructure.

Resources created:

- S3 bucket for Terraform state
- DynamoDB table for state locking

This layer is deployed once and rarely modified.

---

### core

Contains foundational infrastructure that persists across lab sessions.

Examples:

- VPC
- subnets
- route tables
- base security groups

---

### runtime

Contains application-layer infrastructure.

Examples:

- ALB
- ECS
- DynamoDB
- ElastiCache
- WAF
- monitoring resources

This layer is destroyed after each study session to control AWS costs.

---

## Terraform Remote Backend

This project uses a centralized remote backend for Terraform state management.

### Backend Architecture

- S3 bucket for Terraform state storage
- DynamoDB table for state locking
- One shared backend for both environments (dev and prod)
- State keys separated by environment and layer

### State Key Structure

dev/core/terraform.tfstate  
dev/runtime/terraform.tfstate  
prod/core/terraform.tfstate  
prod/runtime/terraform.tfstate  

---

## Initialization Order

1. Deploy the bootstrap layer:

cd infra/bootstrap  
terraform init  
terraform apply  

This creates the S3 bucket and DynamoDB table used for Terraform state.

---

2. Initialize the core infrastructure backend:

cd infra/core  
terraform init -backend-config=backend.hcl  

---

3. Initialize the runtime infrastructure backend:

cd infra/runtime  
terraform init -backend-config=backend.hcl  

Each environment uses its own backend configuration file located inside the respective directory.

---

## State Locking

State locking is enforced via DynamoDB to prevent concurrent Terraform operations.

This protects the infrastructure state from simultaneous modification.

---

## Observability

The system includes basic operational monitoring:

- CloudWatch Logs for container logs
- CloudWatch Alarms monitoring:
  - HTTP 5xx errors
  - target response latency
  - unhealthy targets

These alarms help detect:

- application failures
- latency degradation
- service health issues

---

## Security

Security measures implemented in the architecture include:

- ECS tasks running in private subnets
- Security groups following least-privilege principles
- DynamoDB access through a VPC Endpoint
- Secrets retrieved securely via Interface Endpoint (Secrets Manager)
- AWS WAF protecting the public Application Load Balancer

This design ensures that the application backend does not require public internet access.

---

## CI/CD Pipeline

This project implements a complete CI/CD pipeline for application delivery using GitHub Actions and AWS ECS.

The pipeline is designed following a **build once, deploy many** strategy, using immutable container images and environment-based promotion.

---

## CI/CD Flow Overview

### Development Flow (automatic)

Trigger:
- `push` to `main`

Flow:

1. Run tests and security checks
2. Build application container image
3. Tag image using commit SHA (`sha-*`)
4. Push image to Amazon ECR
5. Deploy automatically to ECS (dev environment)

---

### Production Flow (manual promotion)

Trigger:
- Manual (`workflow_dispatch`)

Input:
- `image_tag` (e.g. `sha-55fb199`)

Flow:

1. Select an existing image from ECR
2. Retrieve current ECS task definition (prod)
3. Update container image
4. Register a new task definition revision
5. Deploy to ECS (prod environment)

Production deployments can be protected using GitHub Environments with required approval.

---

## Pipeline Stages

### 1. Continuous Integration (CI)

Executed on every push:

- Dependency installation
- Vulnerability scan (`pip-audit`)
- Static analysis (`bandit`)
- Automated tests (`pytest`)

Goal:
- Ensure code quality and security before building artifacts

---

### 2. Build & Publish

Executed only on `main`:

- Docker image build
- Image tagging using commit SHA
- Push to shared Amazon ECR repository

Example image: 792025037142.dkr.ecr.us-east-1.amazonaws.com/url-shortener-saa-repository:sha-abc1234


---

### 3. Deployment (Dev)

Automatically executed after image publish:

- Retrieve current ECS task definition
- Replace container image
- Register new revision
- Update ECS service

Deployment strategy:
- Rolling update via ECS

---

### 4. Deployment (Production)

Manual promotion workflow:

- No rebuild is performed
- Same image from dev is reused
- Deployment is controlled and auditable

---

## Deployment Targets

| Environment | Trigger | Strategy |
|------------|--------|----------|
| dev | Automatic (`push to main`) | Continuous deployment |
| prod | Manual (`workflow_dispatch`) | Controlled promotion |

---

## Design Decisions

### Immutable Image Strategy

Images are tagged using commit SHA:

- Ensures traceability
- Avoids mutable tags like `latest`
- Enables safe rollbacks

---

### Build Once, Deploy Many

The same image is reused across environments:

- Eliminates inconsistencies
- Reduces risk of environment drift
- Aligns with production-grade practices

---

### Separation of Concerns

- Terraform manages infrastructure
- GitHub Actions manages application delivery

This prevents unnecessary infrastructure changes during deployments.

---

### OIDC Authentication (No Static Credentials)

GitHub Actions authenticates to AWS using OIDC:

- No long-lived credentials
- Temporary, scoped access
- Least-privilege IAM roles

---

### Environment-Based Security

- Dev deploys automatically
- Prod deploys require manual trigger (and optionally approval)

This reduces risk while maintaining agility.

---

## Failure Handling

### CI Failures

- Pipeline stops before build stage
- Prevents vulnerable or broken code from being deployed

---

### Deployment Failures

- ECS service will not stabilize
- CloudWatch metrics and health checks indicate issues
- Deployment can be retried with a fixed image

---

## Rollback Strategy

Rollback is performed by redeploying a previous image:

1. Identify a previously working image tag (`sha-*`)
2. Trigger the production workflow
3. Provide the previous tag as input

Example: sha-previous123


This restores the previous application version without rebuilding.

---

## Trade-offs

### Simplicity vs Flexibility

- Hardcoded cluster/service names simplify implementation
- Could be parameterized for multi-service scalability

---

### CLI-based Deployment vs Terraform

- Deployment handled via AWS CLI (faster, more flexible)
- Terraform remains focused on infrastructure only

---

### Manual Production Deployment

- Adds operational step
- Increases safety and control

---

## Future Improvements

- Parameterize deployment targets
- Add automated rollback triggers
- Improve deployment observability (metrics and dashboards)
- Introduce canary or blue/green deployments
- Add CI/CD for Terraform itself

---

## AWS Region

All infrastructure is deployed in:

us-east-1

---

## Disclaimer

This is a study and portfolio project and is not intended for production use.
