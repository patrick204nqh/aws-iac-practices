# Architecture Overview

This project sets up a multi-VPC architecture for a market practice environment.

## Network Infrastructure

### VPCs

1. **Production VPC (market-prod)**
   - CIDR: `10.0.0.0/16`
   - Public subnet: `10.0.1.0/24` - For web application and public resources
   - Private subnet: `10.0.2.0/24` - For database and internal resources
   - NAT Gateway deployed in public subnet
   - Internet Gateway for public internet access

2. **Bastion VPC (market-bastion)**
   - CIDR: `192.168.0.0/16`
   - Public subnet: `192.168.1.0/24` - For bastion host
   - Internet Gateway for public internet access

### VPC Peering

- VPC peering connection between market-prod and market-bastion
- Route tables in both VPCs updated for cross-VPC communication
- This allows the bastion host to securely access resources in the production VPC

## Compute Resources

### EC2 Instances

1. **Webapp Instance**
   - Located in: market-prod VPC, public subnet
   - Purpose: Hosts the web application
   - Key features:
     - Docker container running a simple web application
     - Public access on port 80
     - Monitoring via Glances on port 61208
     - Connects to database instance for data storage

2. **Database Instance**
   - Located in: market-prod VPC, private subnet
   - Purpose: Hosts database services
   - Key features:
     - MySQL (port 3306)
     - Redis (port 6379)
     - No direct public internet access
     - Accessible from webapp and bastion host

3. **Bastion Host**
   - Located in: market-bastion VPC, public subnet
   - Purpose: Secure access point for administration
   - Key features:
     - SSH access restricted to your IP address
     - Provides jump-box access to resources in private subnets
     - Includes convenience tools for testing connectivity

## Security

### Security Groups

1. **Webapp Security Group**
   - Allows HTTP (80) from anywhere
   - Allows Glances monitoring (61208) from anywhere
   - Allows SSH (22) from bastion VPC or your IP

2. **Database Security Group**
   - Allows MySQL (3306) from webapp security group
   - Allows Redis (6379) from webapp security group
   - Allows SSH (22) from bastion VPC or your IP

3. **Bastion Security Group**
   - Allows SSH (22) only from your IP address
   - All outbound traffic allowed

## Deployment Information

This architecture is deployed using AWS CDK (Cloud Development Kit), which provides infrastructure as code capabilities to provision all required resources programmatically.

The infrastructure creates encrypted EBS volumes for all EC2 instances and automatically configures user data scripts to bootstrap the environments with required software and configurations.

## Access Pattern

1. Users connect to the webapp via HTTP on its public IP
2. Administrators connect to the bastion host via SSH
3. From the bastion, administrators can connect to webapp and database instances
4. The webapp connects to the database for data storage and caching