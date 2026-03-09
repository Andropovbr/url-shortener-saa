# URL Shortener — AWS Architecture Study Project

## Overview

This project simulates a production-style URL shortener architecture built on AWS using Terraform.

The primary goal is to practice AWS Solutions Architect Associate (SAA-C03) concepts through hands-on infrastructure design, focusing on:

- High availability (Multi-AZ)
- Scalability
- Security best practices
- Infrastructure as Code
- Cost awareness

---

## Project Status

Current progress:

- Milestone 1 — Infrastructure bootstrap
- Milestone 2 — Core networking
- Milestone 3 — Compute layer (ECS + ALB)
- Milestone 4 — Data layer (DynamoDB)
- Milestone 5 — Observability & Security

Future milestones will focus on CI/CD and additional operational improvements.

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

High-level architecture:

Client  
↓  
AWS WAF  
↓  
Application Load Balancer  
↓  
ECS Fargate Service (FastAPI application)  
↓  
DynamoDB  

Additional components:

- CloudWatch Logs for application logging
- CloudWatch Alarms for operational monitoring
- DynamoDB TTL for automatic expiration of URLs
- VPC Endpoint for DynamoDB to avoid NAT Gateway costs

---

## Architecture Goals

The system is designed to include:

- Multi-AZ VPC architecture
- Application Load Balancer
- ECS Fargate service
- DynamoDB data layer
- CloudWatch Logs and Alarms for observability
- AWS WAF for edge protection
- Security best practices
- Infrastructure as Code with Terraform
- Cost-conscious design (no NAT Gateway)

Infrastructure is destroyed after each study session to avoid unnecessary AWS charges.

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

2. Initialize the core infrastructure backend:

cd infra/core  
terraform init -backend-config=backend.hcl  

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

These alarms help detect application failures, performance degradation, and service health issues.

---

## Security

Security measures implemented in the architecture include:

- ECS tasks running in private subnets
- Security groups following least-privilege principles
- DynamoDB access through a VPC Endpoint
- AWS WAF protecting the public Application Load Balancer

This design ensures that the application backend does not require public internet access.

---

## AWS Region

All infrastructure is deployed in:

us-east-1

---

## Disclaimer

This is a study and portfolio project and is not intended for production use.
