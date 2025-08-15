# SuperMarket Cloud Migration - AWS CDK Implementation

This project implements the infrastructure for SuperMarket's cloud migration from failing on-premise servers to a modern AWS-native architecture using AWS CDK.

## Architecture Overview

The solution replaces SuperMarket's basement infrastructure with:

- **VPC**: Multi-tier network with public, private, and database subnets across 2 AZs
- **ECS Fargate**: Containerized web applications with auto-scaling
- **RDS MySQL**: Managed database with Multi-AZ deployment and automated backups
- **ElastiCache Redis**: Dedicated caching layer for improved performance
- **OpenSearch**: Search functionality with zone-awareness
- **Application Load Balancer**: Traffic distribution with health checks
- **Security Groups**: Network-level security with least privilege access

## Project Structure

```
├── lib/
│   └── supermarket-migration-stack.ts  # Main CDK stack definition
├── bin/
│   └── supermarket-migration.ts        # CDK app entry point
├── docs/
│   ├── architecture.md                 # Detailed architecture documentation
│   └── monitoring.md                   # Service monitoring and health checks
├── test/
│   └── supermarket-migration.test.ts   # Unit tests
└── README.md                           # This file
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- AWS CDK CLI installed (`npm install -g aws-cdk`)
- Node.js and npm installed

## Deployment

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Build the project:**
   ```bash
   npm run build
   ```

3. **Bootstrap CDK (first time only):**
   ```bash
   npx cdk bootstrap
   ```

4. **Synthesize CloudFormation template:**
   ```bash
   npx cdk synth
   ```

5. **Deploy the stack:**
   ```bash
   npx cdk deploy
   ```

## Infrastructure Components

### Networking
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.0.0/24, 10.0.1.0/24 (ALB)
- **Private Subnets**: 10.0.2.0/24, 10.0.3.0/24 (ECS, Cache, Search)
- **Database Subnets**: 10.0.4.0/24, 10.0.5.0/24 (RDS - isolated)

### Compute
- **ECS Cluster** with Container Insights enabled
- **Fargate Tasks** running `ghcr.io/patrick204nqh/simple-webapp:latest` with 512MB memory, 256 CPU
- **Auto Scaling** with 2 desired tasks across multiple AZs

### Data Tier
- **RDS MySQL 8.0** on db.t3.micro with Multi-AZ
- **ElastiCache Redis** on cache.t3.micro
- **OpenSearch 2.11** on m6g.small.search (1 node)

### Load Balancing
- **Application Load Balancer** in public subnets
- **Target Group** with health checks on path "/"
- **Security Groups** restricting access between tiers

## Outputs

After deployment, the stack outputs:
- **LoadBalancerURL**: Public URL to access the application
- **DatabaseEndpoint**: RDS endpoint for application configuration

## Security

- Network segmentation with dedicated security groups
- Database in isolated subnets with no internet access
- Least privilege access between application tiers
- Generated secrets for database credentials stored in AWS Secrets Manager

## Cost Considerations

Current configuration uses:
- t3.micro instances for cost optimization
- Single-region deployment (configurable)
- GP2 storage for EBS volumes
- Minimal instance counts suitable for development/testing

## Monitoring

- Container Insights enabled for ECS cluster
- CloudWatch Logs for application containers
- Built-in AWS service monitoring for RDS, ElastiCache, and OpenSearch

## Architecture Documentation

For detailed architecture documentation including C4 diagrams, component details, and deployment procedures, see [docs/architecture.md](docs/architecture.md).

## Next Steps

1. Configure application environment variables for service endpoints
2. Implement CI/CD pipeline for automated deployments
3. Add monitoring dashboards and alerts
4. Configure SSL/TLS certificates for production
5. Set up automated backup verification procedures

## Business Impact

This architecture addresses SuperMarket's key challenges:
- **Eliminates single points of failure** with Multi-AZ deployment
- **Handles traffic spikes** with auto-scaling ECS services
- **Reduces maintenance overhead** with managed AWS services
- **Improves performance** with dedicated caching and search tiers
- **Enables rapid scaling** for business growth

## Useful Commands

* `npm run build`   compile typescript to js
* `npm run watch`   watch for changes and compile
* `npm run test`    perform the jest unit tests
* `npx cdk deploy`  deploy this stack to your default AWS account/region
* `npx cdk diff`    compare deployed stack with current state
* `npx cdk synth`   emits the synthesized CloudFormation template

---

**Note**: This is an educational example demonstrating AWS CDK best practices for cloud migration scenarios.