# 02-Market-Practice Example Requirements

## Overview

An advanced multi-VPC architecture following Terraform best practices with modular design, consistent naming, comprehensive tagging, and environment-specific configurations.

## Business Requirements

### Business Objectives
- Demonstrate advanced infrastructure as code practices using Terraform
- Showcase multi-environment deployment patterns (staging and production)
- Illustrate proper modular design for reusable infrastructure components
- Implement enterprise-grade naming and tagging conventions
- Provide patterns for environment-specific security models

### Success Criteria
- Successfully deploy infrastructure in both staging and production environments
- Implement proper isolation between environments
- Establish secure access patterns appropriate for each environment
- Demonstrate proper module reuse across environments
- Enable monitoring and operational visibility

## Technical Requirements

### AWS Services
- Amazon EC2 (for bastion, web app, and database instances)
- Amazon VPC (for network segmentation)
- VPC Peering (for secure communication between VPCs)
- Internet Gateway
- Route Tables
- Security Groups
- Key Pairs

### Architecture Requirements
- **Networking**:
  - Multi-VPC design with environment-specific configurations
  - Environment-specific CIDR blocks (staging vs production)
  - VPC peering only in staging environment
- **Security**:
  - Environment-specific security models
  - Staging: Bastion host with VPC peering for developer access
  - Production: Completely isolated with no bastion, no VPC peering
  - Emergency access patterns when needed
- **High Availability**:
  - Basic setup without explicit HA requirements (educational example)
- **Scaling**:
  - Environment-specific instance sizing

### Infrastructure Design
- **VPC Configuration**:
  - Staging: 10.2.0.0/16 with bastion VPC at 10.1.0.0/16
  - Production: 10.0.0.0/16 (completely isolated)
- **Instance Sizing**:
  - Staging: t3.micro instances
  - Production: t3.small instances
- **Security Group Rules**:
  - Environment-specific access controls
  - Emergency access options (commented)
- **Database Tier**:
  - Containerized MySQL and Redis running on EC2 instances

## Operational Requirements

### Monitoring
- Glances dashboard for basic instance monitoring
- Access to logs via SSH in staging
- Limited operational access in production

### Cost Optimization
- Environment-appropriate instance sizing
- Single region deployment (ap-southeast-1)

### Security Compliance
- Environment-specific security models
- Complete isolation for production environment
- Proper network segmentation between tiers

## Implementation Constraints

### Prerequisites
- AWS CLI configured for ap-southeast-1 region
- Terraform installed (version compatible with AWS provider ~> 5.0)
- S3 bucket for Terraform state management

### Limitations
- Single-region deployment
- No automated scaling
- No high availability configurations
- No managed database services (uses containerized databases)

## Testing Strategy
- Environment-specific testing strategies
- Staging: Full developer access for testing
- Production: Limited access following strict protocols

## Documentation Requirements
- Architecture diagrams for both environments
- Environment comparison documentation
- Module organization and design patterns
- Best practices implementation guide