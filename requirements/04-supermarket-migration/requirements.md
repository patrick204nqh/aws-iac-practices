# SuperMarket Cloud Migration - Mentee Exercise Requirements

## Overview

A comprehensive mentee exercise designed to practice cloud architecture design, infrastructure implementation, and technical communication skills. Students take on the role of Senior Cloud Engineer consulting for SuperMarket company to migrate from failing on-premise infrastructure to a modern AWS solution.

## Business Requirements

### Business Objectives
- Replace aging on-premise infrastructure with AWS-native solution
- Handle 300% traffic growth expected over 12 months
- Eliminate Black Friday site crashes due to seasonal spikes
- Reduce IT maintenance overhead from 80% to focus on feature development
- Improve competitive position with faster, more reliable platform
- Minimize business risk from single points of failure

### Success Criteria
- Design and implement scalable AWS architecture using CDK
- Handle peak traffic loads without performance degradation
- Achieve 99.9% uptime with proper redundancy
- Demonstrate clear business value proposition through structured presentation
- Successfully lead technical Q&A session showing architectural expertise

## Technical Requirements

### AWS Services
- Amazon ECS with Fargate for containerized applications
- Amazon RDS (MySQL) for managed database with backup strategy
- Amazon ElastiCache (Redis) for caching layer
- Amazon OpenSearch for search functionality
- Application Load Balancer (ALB) for traffic distribution
- Amazon VPC with proper security groups
- AWS CDK for infrastructure as code

### Architecture Requirements
- **Networking**:
  - Multi-tier VPC architecture with proper subnet segmentation
  - Security groups following principle of least privilege
  - Internet Gateway for public access
  - NAT Gateway for private subnet internet access
- **Security**:
  - Network isolation between application tiers
  - Encrypted data at rest and in transit
  - Proper IAM roles and policies
- **High Availability**:
  - Multi-AZ deployment for RDS
  - ECS services distributed across multiple AZs
  - Load balancer health checks and failover
- **Scaling**:
  - Auto-scaling for ECS services based on CPU/memory utilization
  - RDS read replicas for database scaling (if needed)

### Infrastructure Design
- **VPC Configuration**:
  - Public subnets for load balancers
  - Private subnets for application containers
  - Database subnets for RDS instances
- **Load Balancing Strategy**:
  - Application Load Balancer with target groups
  - Health checks for container instances
- **Database Tier**:
  - RDS MySQL with automated backups
  - Multi-AZ deployment for high availability
- **Caching Requirements**:
  - ElastiCache Redis cluster
  - Application-level caching strategy
- **Search Functionality**:
  - OpenSearch cluster for product search
  - Proper indexing and search optimization

## Operational Requirements

### Monitoring
- CloudWatch metrics for all services
- Application performance monitoring
- Database performance insights
- Load balancer metrics and alarms

### Cost Optimization
- Right-sizing of instances based on workload requirements
- Reserved instances for predictable workloads
- Spot instances where appropriate
- Cost allocation tags for budget tracking

### Security Compliance
- AWS security best practices implementation
- Regular security group audits
- Encryption for data at rest and in transit
- Proper access logging and monitoring

## Implementation Constraints

### Prerequisites
- AWS CLI configured with appropriate permissions
- AWS CDK CLI installed and configured
- Node.js runtime for CDK development
- Docker for local container development and testing

### Limitations
- Educational exercise focused on core services
- No CI/CD pipeline implementation (out of scope)
- No advanced monitoring dashboards (out of scope)
- Single region deployment
- Simplified IAM model for educational purposes

## Exercise Structure

### Week 1: Design & Build (Technical Focus)
- **Day 1-2**: Scope definition and project brief
- **Day 3-5**: Architecture design using SCR format (Situation-Complication-Resolution)
- **Day 6-7**: CDK implementation and testing

### Week 2: Present & Lead (Communication Focus)
- **Day 1-3**: Presentation preparation (5-slide format)
- **Day 4-5**: Technical Q&A session leadership practice

## Testing Strategy

### Technical Validation
- CDK stack successful deployment
- All service connectivity tests
- Load testing for performance validation
- Security group rule verification

### Communication Assessment
- Project brief clarity and scope management
- SCR proposal logic and business impact
- Presentation confidence and technical accuracy
- Q&A session leadership and technical authority

## Documentation Requirements

### Technical Documentation
- Architecture diagrams showing all AWS services and connections
- CDK code with clear comments and structure
- Deployment and operational procedures

### Business Documentation
- Project brief with clear scope boundaries
- SCR format proposal (1 page)
- 5-slide presentation covering problem, solution, benefits, implementation, next steps
- Q&A preparation materials

### Success Metrics
- **Technical Success**: Functional deployment, best practices adherence, clean code
- **Communication Success**: Clear scope definition, compelling proposal, confident presentation
- **Leadership Success**: Technical authority demonstration, professional question handling, solution-focused guidance

---

**Note**: This exercise emphasizes both technical implementation skills and professional communication abilities essential for senior engineering roles. The focus is on growth through practical application rather than perfect execution.