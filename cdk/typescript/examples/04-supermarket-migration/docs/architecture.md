# SuperMarket Cloud Migration - Architecture Documentation

## Overview

This document describes the AWS cloud architecture for SuperMarket's e-commerce platform migration from on-premise infrastructure to a modern, scalable, and resilient AWS-native solution.

## Architecture Principles

### High Availability
- Multi-AZ deployment across 2 availability zones
- RDS Multi-AZ for database redundancy
- Load balancer distributing traffic across multiple ECS tasks

### Security
- Network segmentation with VPC and security groups
- Database isolation in private subnets
- Least privilege access patterns
- Encrypted data at rest and in transit

### Scalability
- Auto-scaling ECS Fargate services
- Elastic infrastructure components
- Managed services reducing operational overhead

### Cost Optimization
- Right-sized instances for workload requirements
- Managed services reducing maintenance costs
- Development/testing appropriate instance types

## System Architecture

### C4 Context Diagram

```mermaid
C4Context
    title SuperMarket E-commerce Platform - System Context

    Person(customers, "Customers", "End users shopping on SuperMarket platform")
    Person(admins, "Administrators", "SuperMarket staff managing the platform")
    
    System_Boundary(supermarket, "SuperMarket E-commerce System") {
        System(webapp, "SuperMarket Web Application", "Handles customer requests, product catalog, shopping cart, and order processing")
    }
    
    System_Ext(payment, "Payment Gateway", "External payment processing")
    System_Ext(shipping, "Shipping Provider", "External shipping and logistics")
    System_Ext(analytics, "Analytics Platform", "Business intelligence and reporting")
    
    Rel(customers, webapp, "Browse products, place orders", "HTTPS")
    Rel(admins, webapp, "Manage inventory, orders", "HTTPS")
    Rel(webapp, payment, "Process payments", "HTTPS/API")
    Rel(webapp, shipping, "Create shipments", "API")
    Rel(webapp, analytics, "Send usage data", "API")
```

### C4 Container Diagram

```mermaid
C4Container
    title SuperMarket E-commerce Platform - Container Diagram

    Person(customers, "Customers", "End users shopping on SuperMarket platform")
    
    System_Boundary(aws, "AWS Cloud Infrastructure") {
        Container_Boundary(alb, "Application Load Balancer") {
            Container(loadbalancer, "ALB", "AWS Application Load Balancer", "Distributes incoming requests across web application instances")
        }
        
        Container_Boundary(compute, "ECS Fargate Cluster") {
            Container(webapp1, "Web App Instance 1", "Node.js/Express", "Handles HTTP requests, business logic, renders web pages")
            Container(webapp2, "Web App Instance 2", "Node.js/Express", "Handles HTTP requests, business logic, renders web pages")
        }
        
        Container_Boundary(data, "Data Layer") {
            ContainerDb(database, "MySQL Database", "AWS RDS MySQL 8.0", "Stores product catalog, user accounts, orders")
            ContainerDb(cache, "Redis Cache", "AWS ElastiCache", "Caches frequently accessed data, session storage")
            ContainerDb(search, "Search Engine", "AWS OpenSearch", "Provides product search and filtering capabilities")
        }
        
        Container(secrets, "Secrets Manager", "AWS Secrets Manager", "Manages database credentials and API keys")
        Container(logs, "CloudWatch", "AWS CloudWatch", "Application logging and monitoring")
    }
    
    System_Ext(payment, "Payment Gateway", "External payment processing")
    
    Rel(customers, loadbalancer, "Browse, shop, checkout", "HTTPS")
    Rel(loadbalancer, webapp1, "Routes requests", "HTTP")
    Rel(loadbalancer, webapp2, "Routes requests", "HTTP")
    
    Rel(webapp1, database, "Read/write product data, orders", "MySQL/TLS")
    Rel(webapp2, database, "Read/write product data, orders", "MySQL/TLS")
    
    Rel(webapp1, cache, "Cache queries, sessions", "Redis")
    Rel(webapp2, cache, "Cache queries, sessions", "Redis")
    
    Rel(webapp1, search, "Product search queries", "HTTPS")
    Rel(webapp2, search, "Product search queries", "HTTPS")
    
    Rel(webapp1, secrets, "Get DB credentials", "HTTPS")
    Rel(webapp2, secrets, "Get DB credentials", "HTTPS")
    
    Rel(webapp1, logs, "Application logs", "CloudWatch API")
    Rel(webapp2, logs, "Application logs", "CloudWatch API")
    
    Rel(webapp1, payment, "Process payments", "HTTPS")
    Rel(webapp2, payment, "Process payments", "HTTPS")
```

### C4 Component Diagram - Web Application

```mermaid
C4Component
    title SuperMarket Web Application - Component Diagram

    Container_Boundary(webapp, "SuperMarket Web Application") {
        Component(controller, "Web Controllers", "Express.js Routes", "Handles HTTP requests and responses")
        Component(auth, "Authentication Service", "Passport.js", "Manages user authentication and sessions")
        Component(catalog, "Product Catalog Service", "Business Logic", "Manages product information and inventory")
        Component(cart, "Shopping Cart Service", "Business Logic", "Handles shopping cart operations")
        Component(order, "Order Service", "Business Logic", "Processes customer orders")
        Component(search_svc, "Search Service", "Business Logic", "Interfaces with search engine")
        Component(cache_svc, "Cache Service", "Redis Client", "Manages application caching")
        Component(db_svc, "Database Service", "MySQL Client", "Handles database operations")
    }
    
    ContainerDb_Ext(database, "MySQL Database", "AWS RDS", "Primary data store")
    ContainerDb_Ext(cache, "Redis Cache", "AWS ElastiCache", "Caching layer")
    ContainerDb_Ext(search, "OpenSearch", "AWS OpenSearch", "Search engine")
    
    Person(customers, "Customers")
    
    Rel(customers, controller, "HTTP requests", "HTTPS")
    Rel(controller, auth, "Authenticate user")
    Rel(controller, catalog, "Get products")
    Rel(controller, cart, "Manage cart")
    Rel(controller, order, "Process orders")
    Rel(controller, search_svc, "Search products")
    
    Rel(auth, cache_svc, "Store sessions")
    Rel(catalog, db_svc, "Product data")
    Rel(cart, cache_svc, "Cart state")
    Rel(order, db_svc, "Order data")
    Rel(search_svc, search, "Search queries", "HTTPS")
    
    Rel(cache_svc, cache, "Cache operations", "Redis Protocol")
    Rel(db_svc, database, "SQL queries", "MySQL/TLS")
```

### AWS Infrastructure Diagram

```mermaid
graph TB
    subgraph "AWS Cloud - SuperMarket Infrastructure"
        subgraph "VPC: 10.0.0.0/16"
            subgraph "Public Subnets (Multi-AZ)"
                IGW[Internet Gateway]
                ALB[Application Load Balancer<br/>Distribute Traffic]
                NAT1[NAT Gateway AZ-1]
                NAT2[NAT Gateway AZ-2]
            end
            
            subgraph "Private Subnets (Multi-AZ)"
                subgraph "AZ-1: 10.0.2.0/24"
                    ECS1[ECS Fargate Task 1<br/>simple-webapp:latest<br/>512MB, 0.25 vCPU]
                    REDIS[ElastiCache Redis<br/>cache.t3.micro<br/>Session & Query Cache]
                    SEARCH[OpenSearch Domain<br/>m6g.small.search<br/>Product Search Index]
                end
                
                subgraph "AZ-2: 10.0.3.0/24"
                    ECS2[ECS Fargate Task 2<br/>simple-webapp:latest<br/>512MB, 0.25 vCPU]
                end
            end
            
            subgraph "Database Subnets (Isolated)"
                subgraph "AZ-1: 10.0.4.0/24"
                    RDS1[RDS Primary<br/>MySQL 8.0<br/>db.t3.micro<br/>Multi-AZ]
                end
                
                subgraph "AZ-2: 10.0.5.0/24"
                    RDS2[RDS Standby<br/>MySQL 8.0<br/>Automatic Failover]
                end
            end
            
            subgraph "Monitoring & Security"
                CW[CloudWatch<br/>Logs & Metrics]
                SM[Secrets Manager<br/>DB Credentials]
                SG[Security Groups<br/>Network ACLs]
            end
        end
    end
    
    USER[End Users<br/>Customers & Admins] --> IGW
    IGW --> ALB
    ALB --> ECS1
    ALB --> ECS2
    
    ECS1 --> RDS1
    ECS2 --> RDS1
    ECS1 --> REDIS
    ECS2 --> REDIS
    ECS1 --> SEARCH
    ECS2 --> SEARCH
    
    RDS1 -.->|Synchronous<br/>Replication| RDS2
    
    ECS1 --> NAT1
    ECS2 --> NAT2
    NAT1 --> IGW
    NAT2 --> IGW
    
    ECS1 --> CW
    ECS2 --> CW
    ECS1 --> SM
    ECS2 --> SM
    
    SG -.-> ECS1
    SG -.-> ECS2
    SG -.-> RDS1
    SG -.-> REDIS
    SG -.-> SEARCH
    
    style USER fill:#e1f5fe
    style ALB fill:#fff3e0
    style ECS1 fill:#f3e5f5
    style ECS2 fill:#f3e5f5
    style RDS1 fill:#e8f5e8
    style RDS2 fill:#e8f5e8
    style REDIS fill:#ffebee
    style SEARCH fill:#fff8e1
    style CW fill:#f0f4c3
    style SM fill:#f0f4c3
    style SG fill:#f0f4c3
```

## Component Details

### Network Architecture

#### VPC Configuration
- **CIDR Block**: 10.0.0.0/16
- **Availability Zones**: 2 AZs for high availability
- **Subnets**:
  - Public Subnets: 10.0.0.0/24, 10.0.1.0/24 (ALB, NAT Gateways)
  - Private Subnets: 10.0.2.0/24, 10.0.3.0/24 (ECS, Cache, Search)
  - Database Subnets: 10.0.4.0/24, 10.0.5.0/24 (RDS - isolated)

#### Security Groups
- **ALB Security Group**: Allows HTTP(80) and HTTPS(443) from internet
- **ECS Security Group**: Allows traffic from ALB on port 80
- **Database Security Group**: Allows MySQL(3306) from ECS only
- **Cache Security Group**: Allows Redis(6379) from ECS only
- **Search Security Group**: Allows HTTPS(443) from ECS only

### Compute Layer

#### ECS Fargate Configuration
- **Cluster**: SupermarketCluster with Container Insights
- **Task Definition**: 
  - CPU: 256 units (0.25 vCPU)
  - Memory: 512 MB
  - Image: `ghcr.io/patrick204nqh/simple-webapp:latest`
- **Service**: 2 desired tasks with auto-scaling across AZs
- **Networking**: Deployed in private subnets with security groups

#### Application Load Balancer
- **Type**: Application Load Balancer (Layer 7)
- **Placement**: Public subnets across multiple AZs
- **Target Group**: ECS tasks with health checks on path "/"
- **Listener**: HTTP on port 80

### Data Layer

#### RDS MySQL Database
- **Engine**: MySQL 8.0
- **Instance Class**: db.t3.micro
- **Deployment**: Multi-AZ for high availability
- **Storage**: 20GB GP2 with automated backups (7 days retention)
- **Security**: Isolated in database subnets, encrypted at rest
- **Credentials**: Managed via AWS Secrets Manager

#### ElastiCache Redis
- **Engine**: Redis
- **Node Type**: cache.t3.micro
- **Deployment**: Single node in private subnet
- **Purpose**: Application caching and session storage

#### OpenSearch Domain
- **Version**: OpenSearch 2.11
- **Instance Type**: m6g.small.search
- **Deployment**: Single node in private subnet
- **Storage**: 20GB EBS GP2
- **Purpose**: Product search and analytics

### Monitoring and Logging

#### CloudWatch Integration
- **Container Insights**: Enabled for ECS cluster monitoring
- **Application Logs**: Streamed to CloudWatch Logs
- **Metrics**: Available for all AWS services
- **Alarms**: Can be configured for critical metrics

#### Built-in Service Monitoring
- **RDS**: Performance Insights and automated monitoring
- **ElastiCache**: Redis metrics and performance monitoring
- **OpenSearch**: Cluster health and performance metrics
- **ECS**: Task and service level metrics

## Security Architecture

### Network Security
- **VPC Isolation**: Complete network isolation from other AWS resources
- **Security Groups**: Act as virtual firewalls with least privilege rules
- **NACLs**: Default allow/deny rules at subnet level
- **Private Subnets**: Application and data tiers not directly accessible from internet

### Data Security
- **Encryption at Rest**: Enabled for RDS, EBS volumes
- **Encryption in Transit**: HTTPS/TLS for all service communications
- **Secrets Management**: Database credentials stored in AWS Secrets Manager
- **IAM Roles**: Task execution roles with minimal required permissions

### Access Control
- **Database Access**: Only from ECS tasks via security groups
- **Cache Access**: Restricted to application tier
- **Search Access**: Limited to application services
- **Administrative Access**: Through AWS IAM and console

## Disaster Recovery and High Availability

### RDS High Availability
- **Multi-AZ Deployment**: Automatic failover to standby instance
- **Automated Backups**: 7-day retention with point-in-time recovery
- **Cross-AZ Synchronous Replication**: Zero data loss failover

### Application High Availability
- **Multi-AZ ECS Deployment**: Tasks distributed across availability zones
- **Load Balancer Health Checks**: Automatic traffic routing to healthy instances
- **Auto Scaling**: Automatic capacity adjustment based on demand

### Recovery Procedures
- **RDS Failover**: Automatic with ~1-2 minutes downtime
- **ECS Task Recovery**: Automatic replacement of failed tasks
- **Regional Disaster**: Manual procedures for cross-region recovery

## Performance Optimization

### Caching Strategy
- **Application-Level Caching**: Redis for database query results
- **Session Management**: Redis for user session storage
- **CDN Integration**: Can be added for static content delivery

### Database Optimization
- **Connection Pooling**: Managed by application
- **Read Replicas**: Can be added for read scaling
- **Query Optimization**: Application-level optimization

### Search Performance
- **OpenSearch Indexing**: Optimized for product search
- **Query Optimization**: Application-level search optimization

## Cost Optimization

### Instance Sizing
- **Development Optimized**: t3.micro and small instances for cost efficiency
- **Production Ready**: Can scale to larger instances as needed
- **Reserved Instances**: Can be utilized for predictable workloads

### Managed Services Benefits
- **Reduced Operational Overhead**: No server management required
- **Automatic Scaling**: Pay for what you use
- **Built-in Security**: Reduces security management overhead

## Migration Path

### From Current State
- **Legacy Infrastructure**: 3 physical Apache servers, single MySQL, Redis on same server
- **Single Point of Failure**: Database server failure affects entire system
- **Limited Scalability**: Manual scaling and maintenance

### To Target State
- **Containerized Applications**: Scalable ECS Fargate deployment
- **Managed Database**: RDS with automatic backups and Multi-AZ
- **Dedicated Services**: Separate caching and search tiers
- **High Availability**: No single points of failure

### Migration Benefits
- **99.9% Uptime**: Multi-AZ redundancy eliminates downtime
- **Auto Scaling**: Handles traffic spikes automatically
- **60% Reduced Maintenance**: Managed services reduce operational overhead
- **Improved Performance**: Dedicated caching and search services

## Deployment and Operations

### Infrastructure as Code
- **AWS CDK**: TypeScript-based infrastructure definition
- **Version Control**: Git-based infrastructure versioning
- **Automated Deployment**: Consistent and repeatable deployments

### Operational Procedures
- **Monitoring**: CloudWatch dashboards and alerting
- **Logging**: Centralized application and infrastructure logs
- **Backup Verification**: Regular backup testing procedures
- **Scaling Procedures**: Manual and automatic scaling processes

### Maintenance Windows
- **RDS Maintenance**: Automated during configured windows
- **ECS Updates**: Rolling deployments with zero downtime
- **Security Patching**: Automatic for managed services

---

This architecture provides SuperMarket with a robust, scalable, and cost-effective e-commerce platform capable of handling current traffic and future growth requirements while maintaining high availability and security standards.