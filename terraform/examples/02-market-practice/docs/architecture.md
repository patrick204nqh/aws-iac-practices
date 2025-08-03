# Architecture Diagrams

This document shows the architecture for both staging and production environments, highlighting their different security and cost optimization approaches.

## Staging Environment Architecture

```mermaid
---
title: Staging Environment - Multi-VPC with Bastion Access
---
C4Container
    Person(user, "Developer", "Accesses web application and SSH via bastion")
    Person(admin, "Admin", "SSH access via bastion")

    Enterprise_Boundary(bastion_vpc, "Bastion VPC (10.1.0.0/16)") {
        System_Boundary(bastion_public_subnet, "Public Subnet (10.1.1.0/24)") {
            Container(bastion, "Bastion Host", "t3.micro, 8GB", "SSH gateway")
        }
    }

    Enterprise_Boundary(staging_vpc, "Staging VPC (10.2.0.0/16)") {
        System_Boundary(staging_public_subnet, "Public Subnet (10.2.1.0/24)") {
            Container(staging_webapp, "Web App", "t3.micro, 10GB", "HTTP + Monitoring")
        }
        
        System_Boundary(staging_private_subnet, "Private Subnet (10.2.2.0/24)") {
            Container(staging_database, "Database EC2", "t3.micro, 12GB", "MySQL + Redis containers")
        }
    }

    Rel(user, staging_webapp, "HTTP", "80, 61208")
    Rel(admin, bastion, "SSH", "22")
    Rel(bastion, staging_webapp, "SSH", "via VPC peering")
    Rel(bastion, staging_database, "SSH", "via VPC peering")
    Rel(staging_webapp, staging_database, "DB Queries", "3306, 6379")

    UpdateElementStyle(user, $bgColor="lightblue")
    UpdateElementStyle(admin, $bgColor="lightblue")
    UpdateElementStyle(staging_webapp, $bgColor="green")
    UpdateElementStyle(staging_database, $bgColor="blue")
    UpdateElementStyle(bastion, $bgColor="orange")
```

## Production Environment Architecture

```mermaid
---
title: Production Environment - Isolated Single VPC
---
C4Container
    Person(prod_user, "User", "Accesses web application")

    Enterprise_Boundary(prod_vpc, "Production VPC (10.0.0.0/16)") {
        System_Boundary(prod_public_subnet, "Public Subnet (10.0.1.0/24)") {
            Container(prod_webapp, "Web App", "t3.small, 10GB", "HTTP + Monitoring")
            Container(prod_nat, "NAT Gateway", "AWS", "Internet for private subnet")
        }
        
        System_Boundary(prod_private_subnet, "Private Subnet (10.0.2.0/24)") {
            Container(prod_database, "Database EC2", "t3.small, 12GB", "MySQL + Redis containers")
        }
    }

    Rel(prod_user, prod_webapp, "HTTP", "80, 61208")
    Rel(prod_webapp, prod_database, "DB Queries", "3306, 6379")
    Rel(prod_database, prod_nat, "Updates", "Internet access")

    UpdateElementStyle(prod_user, $bgColor="lightblue")
    UpdateElementStyle(prod_webapp, $bgColor="green")
    UpdateElementStyle(prod_mysql, $bgColor="blue")
    UpdateElementStyle(prod_redis, $bgColor="blue")
    UpdateElementStyle(prod_database, $bgColor="blue")
    UpdateElementStyle(prod_nat, $bgColor="gray")
```

## Environment Comparison

| Feature | Staging | Production |
|---------|---------|------------|
| **VPC Design** | Multi-VPC (App + Bastion) | Single VPC (Isolated) |
| **VPC CIDR** | 10.2.0.0/16 | 10.0.0.0/16 |
| **Bastion Host** | ✅ Deployed (10.1.0.0/16) | ❌ Not deployed |
| **VPC Peering** | ✅ Enabled | ❌ Disabled |
| **NAT Gateway** | ❌ Disabled (cost optimization) | ✅ Enabled (security) |
| **SSH Access** | Via bastion only | Emergency access only |
| **Instance Types** | t3.micro | t3.small |
| **Storage** | Cost-optimized (8-12GB) | Cost-optimized (10-12GB) |

## Security Models

### **Staging Environment (Development Access)**
- **Purpose**: Development, testing, and debugging
- **Access Pattern**: All SSH goes through bastion host
- **Cost Optimization**: No NAT gateway, smaller instances, reduced storage
- **Network**: Multi-VPC with peering for secure access
- **Emergency SSH**: Can be enabled by uncommenting rules in security groups

### **Production Environment (Maximum Isolation)**
- **Purpose**: Production workloads with maximum security
- **Access Pattern**: No SSH access by design (completely isolated)
- **Security**: Single VPC, no bastion, no VPC peering
- **Network**: NAT gateway for private subnet internet access
- **Emergency SSH**: Can be enabled by uncommenting rules in security groups (use with extreme caution)

## Cost Optimization Features

- **Storage**: 50-60% reduction in EBS volumes (8GB bastion, 10GB webapp, 12GB database)
- **NAT Gateway**: Removed from staging (~$45/month savings)
- **Instance Sizing**: Environment-appropriate sizing (micro vs small)
- **Volume Type**: gp3 volumes for better price/performance
- **Resource Tagging**: Comprehensive cost allocation tags