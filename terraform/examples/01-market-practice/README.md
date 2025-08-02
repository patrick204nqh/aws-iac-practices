# 01 - Market Practice

Multi-VPC architecture with bastion host, web application, and database services demonstrating secure AWS networking patterns.

## Architecture

See [architecture diagram](./docs/architecture.md) for detailed C4 visualization.

## Features
- **Multi-VPC Design**: Separate VPCs for production and management
- **Secure Access**: Bastion host pattern with VPC peering
- **Network Segmentation**: Public/private subnets with proper routing
- **Containerized Services**: Docker containers for web app and databases
- **Monitoring**: Built-in Glances dashboard
- **State Management**: S3 backend with DynamoDB locking
- **Auto SSH Keys**: Automatic key pair generation ([learn more](./docs/ssh-keys.md))
- **Single Region**: All resources in ap-southeast-1 (Singapore)

## Quick Start

⚠️ **Important**: This example deploys all resources in **ap-southeast-1** (Singapore) region. Make sure your AWS CLI is configured for ap-southeast-1.

1. **Prerequisites**
   ```bash
   # Ensure you're using ap-southeast-1 (Singapore)
   aws configure get region  # Should show: ap-southeast-1
   ```

2. **Backend Setup** (One-time)
   
   See [backend setup guide](./docs/backend-setup.md) for detailed S3 and DynamoDB setup instructions.

3. **Deploy**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars: set your IP address (aws_region is fixed to ap-southeast-1)
   
   terraform init
   terraform apply
   ```

4. **Access**
   - Web App: `http://<webapp_ip>`
   - SSH: Use commands from `terraform output ssh_commands`

5. **Clean Up**
   ```bash
   terraform destroy
   ```