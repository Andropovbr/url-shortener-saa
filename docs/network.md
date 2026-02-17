# Network Design

## Region
- us-east-1

## Environments
This project uses isolated environments with separate VPCs:
- dev
- prod

## VPC CIDRs
- dev: 10.0.0.0/16
- prod: 10.1.0.0/16

## Subnet Layout (2 AZs)

### DEV
| Tier         | AZ-a         | AZ-b         |
|--------------|--------------|--------------|
| Public       | 10.0.0.0/24  | 10.0.1.0/24  |
| Private App  | 10.0.10.0/24 | 10.0.11.0/24 |
| Private Data | 10.0.20.0/24 | 10.0.21.0/24 |
| Reserve      | 10.0.30.0/24 | 10.0.31.0/24 |

### PROD
| Tier         | AZ-a         | AZ-b         |
|--------------|--------------|--------------|
| Public       | 10.1.0.0/24  | 10.1.1.0/24  |
| Private App  | 10.1.10.0/24 | 10.1.11.0/24 |
| Private Data | 10.1.20.0/24 | 10.1.21.0/24 |
| Reserve      | 10.1.30.0/24 | 10.1.31.0/24 |

## Routing Strategy (Initial Phase)
- Public subnets route 0.0.0.0/0 to an Internet Gateway (IGW).
- Private subnets initially have no direct internet egress (no NAT Gateway by default) to keep lab costs low.
- Egress strategy may evolve later (e.g., VPC endpoints for ECR/S3, or NAT when required).

## Notes
- Avoid hardcoding AZ names when possible.
- Keep security group boundaries tight: ALB is public, ECS tasks are private.