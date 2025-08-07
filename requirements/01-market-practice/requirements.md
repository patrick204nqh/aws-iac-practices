# 01-Market-Practice Example Requirements

## Overview

This example demonstrates a multi-VPC architecture with bastion host, web application, and database services implementing secure AWS networking patterns.

## Business Requirements

### Business Objectives
- Demonstrate best practices for secure AWS networking patterns
- Illustrate proper network segmentation using multiple VPCs
- Showcase secure remote access patterns using bastion hosts
- Provide a working example of containerized web and database services
- Establish a foundation for more advanced AWS infrastructure patterns

### Success Criteria
- Successfully deploy a working web application accessible via HTTP
- Establish secure SSH access to instances via bastion host
- Demonstrate functional database connectivity between application and database tiers
- Implement proper network isolation between public and private resources
- Enable monitoring via Glances dashboard

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
  - Multi-VPC design with separate VPCs for production and management
  - Public/private subnet segmentation with proper routing
  - VPC peering connection between bastion VPC and production VPC
- **Security**:
  - Bastion host access pattern for secure SSH access
  - Security group rules limiting access based on principle of least privilege
  - SSH key-based authentication
- **High Availability**:
  - Basic setup without explicit HA requirements (educational example)
- **Scaling**:
  - Manual scaling (no auto-scaling requirements for this example)

### Infrastructure Design
- **VPC Configuration**:
  - Bastion VPC: 10.1.0.0/16
  - Production VPC: 10.0.0.0/16
- **Subnet Configuration**:
  - Public subnets in both VPCs
  - Private subnet in production VPC for databases
- **Security Group Rules**:
  - Restrict SSH access to bastion from authorized IPs only
  - Allow SSH from bastion to web and database instances
  - Allow HTTP (80) and monitoring (61208) to web instances
  - Restrict database access to web tier only
- **Load Balancing**:
  - Not required for this basic example
- **Database Tier**:
  - Containerized MySQL and Redis running on EC2 instances
- **Caching**:
  - Containerized Redis for caching

## Operational Requirements

### Monitoring
- Glances dashboard for basic instance monitoring
- Access to logs via SSH

### Cost Optimization
- Use of t3.micro instances to minimize costs
- Single region deployment (ap-southeast-1)

### Security Compliance
- SSH access via bastion only
- No direct public access to database tier
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
- Manual verification of SSH access via bastion
- Web application accessibility testing
- Database connectivity testing from web tier

## Documentation Requirements
- Architecture diagram (C4 model)
- SSH access instructions
- Deployment guide with Terraform commands
- Infrastructure description