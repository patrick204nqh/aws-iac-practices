# 01 - Market Practice

First example in our AWS infrastructure practice series. This creates a multi-VPC architecture with service monitoring.

## What You'll Learn

- 🌐 VPC creation and networking
- 🔒 Security groups and network ACLs
- 🌉 VPC peering connections
- 🖥️ Public/private subnet design
- 🐳 Container deployment on EC2
- 🔍 Service monitoring and health checks
- 🔑 Bastion host patterns

## Architecture

- **market-prod VPC (10.0.0.0/16)**
  - Public subnet: Web application with monitoring
  - Private subnet: MySQL and Redis databases
  - NAT Gateway for private subnet internet access

- **market-bastion VPC (10.1.0.0/16)**
  - Public subnet: Bastion host for SSH access
  - VPC peering with market-prod

## Quick Start

1. **Prerequisites**
   - AWS CLI configured
   - Existing EC2 key pair
   - Your public IP address

2. **Configure**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access Services**
   - Web App: `http://<webapp_public_ip>`
   - Glances: `http://<webapp_public_ip>:61208`
   - SSH via Bastion: Use the commands from terraform output

5. **Test Connectivity**
   ```bash
   # SSH to bastion
   ssh -i your-key.pem ubuntu@<bastion_ip>
   
   # From bastion, test connections
   ./test-connections.sh
   
   # SSH to other instances
   ssh webapp
   ssh database
   ```

6. **Clean Up** (IMPORTANT!)
   ```bash
   terraform destroy
   ```

## Features

- ✅ Multi-VPC architecture
- ✅ Public/Private subnet design
- ✅ VPC peering
- ✅ Bastion host for secure access
- ✅ Service monitoring with simple-webapp
- ✅ MySQL and Redis in containers
- ✅ Automatic service discovery

## Cost Optimization

- Use t3.micro instances (free tier)
- Destroy resources when not in use
- Consider removing NAT Gateway to save $32/month

## Security Notes

- Update `my_ip` variable with your current IP
- Use strong passwords in production
- Rotate SSH keys regularly
- Enable VPC Flow Logs for monitoring