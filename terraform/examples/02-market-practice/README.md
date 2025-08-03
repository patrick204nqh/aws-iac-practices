# 02 - Market Practice (Advanced)

Advanced multi-VPC architecture building on [01-market-practice](../01-market-practice/) with enhanced security, monitoring, and scalability features.

## Architecture

See [architecture diagram](./docs/architecture.md) for detailed C4 visualization.

## Features
- **Multi-VPC Design**: Separate VPCs for production and management
- **Secure Access**: Bastion host pattern with VPC peering
- **Network Segmentation**: Public/private subnets with proper routing
- **Containerized Services**: Docker containers for web app and databases
- **Monitoring**: Built-in Glances dashboard
- **State Management**: S3 backend
- **Auto SSH Keys**: Automatic key pair generation ([learn more](../01-market-practice/docs/ssh-keys.md))
- **Single Region**: All resources in ap-southeast-1 (Singapore)

## Quick Start

⚠️ **Important**: This example deploys all resources in **ap-southeast-1** (Singapore) region. Make sure your AWS CLI is configured for ap-southeast-1.

1. **Prerequisites**
   
   Complete the setup from [01-market-practice](../01-market-practice/#quick-start) first, including:
   - AWS CLI configuration for ap-southeast-1 region
   - S3 backend setup (see [backend setup guide](../01-market-practice/docs/backend-setup.md))

2. **Deploy**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Get your current IP address (see 01-market-practice for details)
   curl ifconfig.me
   # Edit terraform.tfvars: set your IP address (aws_region is fixed to ap-southeast-1)
   
   terraform init
   terraform apply
   ```

3. **Access**
   - Web App: `http://<webapp_ip>`
   - SSH: Use commands from `terraform output ssh_commands`

4. **Clean Up**
   ```bash
   terraform destroy
   ```