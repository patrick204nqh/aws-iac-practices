# 03-Market-Practice Example Requirements

## Overview

An advanced multi-VPC architecture following Terraform best practices with modular design, consistent naming, comprehensive tagging, and environment-specific configurations, enhanced with native AWS managed database services (RDS and ElastiCache).

## Business Requirements

### Business Objectives
- Demonstrate enterprise-grade infrastructure patterns using managed AWS services
- Showcase multi-environment deployment patterns with environment-specific optimizations
- Illustrate proper use of AWS managed database services (RDS MySQL and ElastiCache Redis)
- Implement secure networking patterns for production workloads
- Provide cost-optimized infrastructure designs across different environments

### Success Criteria
- Successfully deploy infrastructure using managed AWS database services
- Implement proper isolation between components and environments
- Establish secure access patterns appropriate for each environment
- Demonstrate backup, recovery, and monitoring capabilities
- Enable operational efficiency through managed services

## Technical Requirements

### AWS Services
- Amazon EC2 (for web app and bastion instances)
- Amazon VPC (for network segmentation)
- VPC Peering (for secure communication between VPCs in staging)
- Amazon RDS MySQL (for managed database service)
- Amazon ElastiCache Redis (for managed caching service)
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
  - Encryption at rest and in transit for database services
- **High Availability**:
  - Environment-specific HA requirements
  - Production: Multi-AZ for RDS and ElastiCache
  - Staging: Single-AZ for cost optimization
- **Scaling**:
  - Environment-specific instance sizing
  - Auto-scaling capabilities for managed services

### Infrastructure Design
- **VPC Configuration**:
  - Staging: 10.2.0.0/16 with bastion VPC at 10.1.0.0/16
  - Production: 10.0.0.0/16 (completely isolated)
- **Instance Sizing**:
  - Staging: t3.micro instances, db.t3.micro for RDS, cache.t3.micro for Redis
  - Production: t3.small instances, db.t3.small for RDS, cache.t3.small for Redis
- **Security Group Rules**:
  - Environment-specific access controls
  - Emergency access options (commented)
- **Database Tier**:
  - RDS MySQL with environment-specific configurations
  - ElastiCache Redis with environment-specific configurations
- **Backup Strategy**:
  - Staging: 1-day retention for RDS, 1 snapshot for Redis
  - Production: 7-day retention for RDS, 5 snapshots for Redis

## Operational Requirements

### Monitoring
- Glances dashboard for web application monitoring
- CloudWatch metrics for RDS and ElastiCache
- Performance Insights for RDS (optional)

### Cost Optimization
- Environment-appropriate instance sizing
- Single-AZ vs Multi-AZ based on environment
- Appropriate backup retention periods
- GP3 storage for improved price/performance

### Security Compliance
- Environment-specific security models
- Complete isolation for production environment
- Encryption at rest and in transit
- Proper network segmentation between tiers

## Implementation Constraints

### Prerequisites
- AWS CLI configured for ap-southeast-1 region
- Terraform installed (version compatible with AWS provider ~> 5.0)
- S3 bucket for Terraform state management

### Limitations
- Single-region deployment
- No automated application scaling (only database tier)

## Testing Strategy
- Environment-specific testing strategies
- Staging: Full developer access for testing
- Production: Limited access following strict protocols
- Database performance testing
- Backup and restore testing

## Documentation Requirements
- Architecture diagrams for both environments
- Environment comparison documentation
- Database management guide
- Backup and recovery procedures
- SSH access documentation