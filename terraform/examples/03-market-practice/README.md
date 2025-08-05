# 03 - Market Practice (Advanced & Refactored)

Advanced multi-VPC architecture following Terraform best practices with modular design, consistent naming, comprehensive tagging, and environment-specific configurations.

## Architecture

See [architecture diagram](./docs/architecture.md) for detailed C4 visualization.

## Features

### Infrastructure Best Practices
- **🏗️ Modular Architecture**: Reusable modules for VPC, compute, and security
- **🏷️ Consistent Tagging**: Comprehensive tagging strategy with project, environment, and cost tracking
- **📝 Naming Convention**: Standardized `project-environment-resource` naming pattern
- **🔧 Configuration Management**: Environment-specific settings via locals and data structures
- **📁 Organized Structure**: Logical file organization and separation of concerns

### Multi-Environment Support
- **🌍 Environment Isolation**: Separate configurations for staging and production
- **🔢 Environment-Specific CIDRs**: Staging (10.2.x.x) vs Production (10.0.x.x)
- **📏 Instance Sizing**: Environment-appropriate instance types (micro vs small)
- **🔒 Security Models**: Staging has bastion access, Production is fully isolated
- **⚙️ Automated Configuration**: Environment-specific access patterns and infrastructure

### Network & Security
- **🏢 Multi-VPC Design**: Separate VPCs for applications and management (staging only)
- **🔒 Environment-Specific Security Models**: 
  - **Staging**: Bastion host + VPC peering for secure development access
  - **Production**: Completely isolated, no bastion, no VPC peering, emergency access only
- **🚨 Emergency Access**: Commented option for temporary direct SSH when absolutely needed
- **🌐 Network Segmentation**: Public/private subnets with proper routing
- **🛡️ Security Groups**: Dynamic rules based on environment and emergency flags

### Native AWS Services
- **🗄️ Amazon RDS MySQL**: Managed MySQL database with automated backups
- **🚀 Amazon ElastiCache Redis**: High-performance managed Redis caching
- **🔒 Built-in Security**: Encryption at rest and in transit
- **📈 Auto Scaling**: Managed service scaling and maintenance

### Operations & Monitoring
- **📊 Monitoring**: Built-in Glances dashboard
- **🔑 Auto SSH Keys**: Automatic key pair generation
- **📦 Containerized Web App**: Docker containers for web application
- **💾 State Management**: S3 backend with environment separation

## Quick Start

⚠️ **Important**: This example deploys all resources in **ap-southeast-1** (Singapore) region. Make sure your AWS CLI is configured for ap-southeast-1.

1. **Prerequisites**
   
   Complete the setup from [01-market-practice](../01-market-practice/#quick-start) first, including:
   - AWS CLI configuration for ap-southeast-1 region
   - S3 backend setup (see [backend setup guide](../01-market-practice/docs/backend-setup.md))

2. **Deploy**
   ```bash
   # Get your current IP address
   curl ifconfig.me
   
   # Copy and edit the terraform.tfvars file
   cp terraform.tfvars.example terraform.tfvars
   nano terraform.tfvars  # Edit with your IP and database password
   
   # Deploy infrastructure
   terraform init
   terraform plan
   terraform apply
   ```

3. **Access**
   
   **SSH Access:**
   ```bash
   # Get SSH commands from Terraform outputs
   terraform output ssh_commands
   
   # Example: Connect to bastion (copy command from output)
   ssh -i ./market-practice-key.pem ubuntu@<bastion-ip>
   
   # Example: Connect to webapp via bastion (copy command from output) 
   ssh -i ./market-practice-key.pem -o ProxyCommand="ssh -i ./market-practice-key.pem -o StrictHostKeyChecking=no -W %h:%p ubuntu@<bastion-ip>" -o StrictHostKeyChecking=no ubuntu@<webapp-ip>
   ```
   
   **Web Access:**
   - Web App: Use `terraform output webapp_url`
   - Monitoring: Use `terraform output glances_url`
   
   **Database Access:**
   - RDS Endpoint: Use `terraform output database_info`
   - Redis Endpoint: Use `terraform output database_info`
   
   **Manual SSH (if needed):**
   - See commands from `terraform output ssh_commands`
   - Or check [SSH Access Guide](./docs/ssh-access.md) for detailed instructions

4. **Clean Up**
   ```bash
   # Destroy infrastructure
   terraform destroy
   ```

## Project Structure

```
03-market-practice/
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                   # VPC module (networking)
│   ├── compute/               # EC2 instance module
│   └── security/              # Security groups module
├── user-data/                 # EC2 user data scripts
├── docs/                      # Documentation
├── locals.tf                  # Local values and environment configs
├── main.tf                    # Main infrastructure (VPCs, modules)
├── compute.tf                 # Web application instances
├── rds.tf                     # Amazon RDS MySQL database
├── elasticache.tf             # Amazon ElastiCache Redis
├── key-pair.tf               # SSH key management
├── outputs.tf                # Output definitions
├── variables.tf              # Input variables
├── versions.tf               # Terraform and provider versions
├── backend.tf                # Remote state configuration
└── terraform.tfvars.example  # Example configuration file
```

## Best Practices Implemented

### 1. **Modular Design**
- Reusable modules for VPC, compute, and security components
- Clear separation of concerns and logical organization
- Module inputs/outputs with proper documentation

### 2. **Configuration Management**
- Environment-specific settings in `locals.tf`
- Centralized configuration with environment-based branching
- Automated instance sizing and CIDR allocation

### 3. **Naming & Tagging**
- Consistent naming: `project-environment-resource`
- Comprehensive tagging for cost tracking and management
- Environment-aware resource naming

### 4. **Security & Operations**
- Environment-specific security group rules
- Proper resource dependencies and lifecycle management
- Encrypted storage and secure key management

## Native AWS Services Benefits

### Amazon RDS MySQL
- **Automated Backups**: Point-in-time recovery and automated backups
- **High Availability**: Multi-AZ deployments for production environments
- **Security**: Encryption at rest and in transit, VPC security groups
- **Maintenance**: Automated patching and maintenance windows
- **Monitoring**: Built-in CloudWatch metrics and Performance Insights

### Amazon ElastiCache Redis
- **High Performance**: In-memory caching with sub-millisecond latency
- **Scalability**: Easy horizontal and vertical scaling
- **Security**: VPC isolation, encryption, and access control
- **Reliability**: Automatic failover and data replication
- **Cost Effective**: Pay only for what you use with no upfront costs

This architecture eliminates the need for custom AMI management and provides enterprise-grade database services with minimal operational overhead.