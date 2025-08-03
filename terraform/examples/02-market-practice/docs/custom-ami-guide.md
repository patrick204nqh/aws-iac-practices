# Custom AMI Management Guide

This guide provides a complete workflow for building, managing, and maintaining custom AMIs with pre-pulled Docker images for cost optimization.

## Overview

Custom AMIs eliminate the need for NAT gateways in staging environments by pre-pulling Docker images during the build process. This approach reduces monthly AWS costs by ~$45 while improving instance startup times.

**Environment Strategy:**
- **Staging**: Custom AMI (no NAT gateway required)
- **Production**: Standard Ubuntu AMI (with NAT gateway for security)

## Prerequisites

### Required Tools
1. **Packer** - [Download Latest Version](https://www.packer.io/downloads)
2. **AWS CLI** - Configured with appropriate credentials

### AWS Permissions
Your AWS user/role needs these permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CopyImage",
        "ec2:CreateImage",
        "ec2:CreateKeypair",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteKeyPair",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSnapshot",
        "ec2:DeleteVolume",
        "ec2:DeregisterImage",
        "ec2:DescribeImageAttribute",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeRegions",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSnapshots",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "ec2:GetPasswordData",
        "ec2:ModifyImageAttribute",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifySnapshotAttribute",
        "ec2:RegisterImage",
        "ec2:RunInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

### Installation
```bash
# Install Packer (Linux/MacOS)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Verify installation
packer version

# Verify AWS CLI
aws sts get-caller-identity
```

## Building Custom AMIs

### Quick Start
```bash
# Navigate to project directory
cd terraform/examples/02-market-practice

# Initialize Packer (required on first run)
packer init packer/

# Build AMI using the provided script
./packer/build-ami.sh

# Or run Packer manually with custom variables
packer build \
    -var "aws_region=ap-southeast-1" \
    -var "instance_type=t3.micro" \
    -var "ami_name_prefix=market-database" \
    packer/database-ami.pkr.hcl
```

### Build Process
1. **Creates temporary EC2 instance** (t3.micro by default)
2. **Installs Docker and Docker Compose**
3. **Pre-pulls required Docker images:**
   - `mysql:8.0`
   - `redis:7-alpine`
4. **Configures systemd service** for auto-start
5. **Creates AMI snapshot** and terminates build instance

### Build Output
```
==> amazon-ebs.database: AMI ami-0a1b2c3d4e5f67890 created successfully
Build completed! AMI ID: ami-0a1b2c3d4e5f67890
```

### Verify Build Success
```bash
# List your custom AMIs
aws ec2 describe-images \
    --owners self \
    --filters 'Name=name,Values=market-database-*' \
    --query 'Images[*].{ImageId:ImageId,Name:Name,CreationDate:CreationDate,State:State}' \
    --output table

# Test instance launch (optional)
aws ec2 run-instances \
    --image-id ami-xxxxxxxxx \
    --instance-type t3.micro \
    --key-name your-key-pair \
    --security-group-ids sg-xxxxxxxxx \
    --subnet-id subnet-xxxxxxxxx \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-database}]'
```

## What's Included in the Custom AMI

### Pre-installed Software
- **Docker CE** - Latest stable version
- **Docker Compose** - Standalone binary
- **MySQL 8.0 Docker image** - Pre-pulled
- **Redis 7 Alpine Docker image** - Pre-pulled

### Auto-start Configuration
- **Systemd service** - `database-services.service` 
- **Docker Compose file** - Located at `/home/ubuntu/docker-compose.yml`
- **Startup script** - `/usr/local/bin/start-database-services.sh`

### Container Configuration
The AMI includes a pre-configured docker-compose.yml with:

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: market_mysql
    environment:
      MYSQL_ROOT_PASSWORD: marketroot123
      MYSQL_DATABASE: market
      MYSQL_USER: market_user
      MYSQL_PASSWORD: market_pass123
    ports: ["3306:3306"]
    
  redis:
    image: redis:7-alpine
    container_name: market_redis
    command: redis-server --requirepass market_redis123
    ports: ["6379:6379"]
```

## Using the Custom AMI

### Terraform Integration
The custom AMI is conditionally used only for staging environment:

```hcl
# main.tf - Both AMI sources available
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  # ... filters
}

data "aws_ami" "database_custom" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["market-database-*"]
  }
}

# compute.tf - Environment-specific AMI selection
module "database" {
  ami_id    = var.environment == "staging" ? data.aws_ami.database_custom.id : data.aws_ami.ubuntu.id
  user_data = var.environment == "staging" ? file("database-custom.sh") : file("database.sh")
  # ... other configuration
}
```

### Instance Startup Process

**Staging Environment (Custom AMI):**
1. Instance boots from custom AMI
2. `database-services.service` starts automatically
3. Docker containers start from pre-pulled images
4. Services are ready ~30 seconds after boot

**Production Environment (Standard Ubuntu AMI):**
1. Instance boots from Ubuntu AMI
2. User-data script runs to install Docker
3. Docker images pulled from internet via NAT gateway
4. Services are ready ~3-5 minutes after boot

## Cost Analysis

### Without Custom AMI (NAT Gateway Required)
- NAT Gateway: $32.40/month (720 hours × $0.045)
- NAT Gateway Data: ~$13.50/month (300 GB × $0.045)
- **Total: ~$45.90/month**

### With Custom AMI
- AMI Storage: ~$0.75/month (15 GB × $0.05)
- Build Time: ~10 minutes monthly for updates
- **Total: ~$0.75/month**

**Monthly Savings: ~$45/month**

## AMI Lifecycle Management

### 1. Regular Maintenance Schedule

| **Frequency** | **Trigger** | **Action** |
|---------------|-------------|------------|
| **Monthly** | Security patches | Rebuild AMI with latest base image |
| **As Needed** | Docker image updates | Update pre-pulled images |
| **Quarterly** | Major OS updates | Full rebuild with Ubuntu updates |

### 2. Version Management Strategy

AMIs use timestamp naming: `market-database-20241203145230`
- **Terraform automatically selects** the most recent AMI
- **Keep 3 most recent versions** for rollback capability
- **Cleanup older versions** to control costs

### 3. Automated Cleanup Script

Create and use this script to manage AMI lifecycle:

```bash
# Create cleanup script
cat << 'EOF' > scripts/cleanup-old-amis.sh
#!/bin/bash
set -e

KEEP_COUNT=${1:-3}  # Keep 3 most recent by default
AMI_PREFIX="market-database"

echo "🔍 Finding AMIs to cleanup (keeping ${KEEP_COUNT} most recent)..."

# Get AMI IDs sorted by creation date (oldest first), excluding the most recent N
OLD_AMIS=$(aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=${AMI_PREFIX}-*" \
    --query "sort_by(Images, &CreationDate)[:-${KEEP_COUNT}].[ImageId,Name,CreationDate]" \
    --output text)

if [ -z "$OLD_AMIS" ]; then
    echo "✅ No old AMIs to cleanup"
    exit 0
fi

echo "📋 AMIs to remove:"
echo "$OLD_AMIS" | while IFS=$'\t' read -r ami_id name creation_date; do
    echo "  - $ami_id ($name) - $creation_date"
done

echo ""
read -p "🗑️  Proceed with deletion? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ Cancelled"
    exit 0
fi

# Delete AMIs and associated snapshots
echo "$OLD_AMIS" | while IFS=$'\t' read -r ami_id name creation_date; do
    echo "🗑️  Removing AMI: $ami_id ($name)"
    
    # Get associated snapshots
    SNAPSHOTS=$(aws ec2 describe-images \
        --image-ids $ami_id \
        --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId!=null].Ebs.SnapshotId' \
        --output text)
    
    # Deregister AMI
    aws ec2 deregister-image --image-id $ami_id
    echo "  ✅ AMI deregistered"
    
    # Delete snapshots
    if [ -n "$SNAPSHOTS" ] && [ "$SNAPSHOTS" != "None" ]; then
        for snapshot_id in $SNAPSHOTS; do
            echo "  🗑️  Deleting snapshot: $snapshot_id"
            aws ec2 delete-snapshot --snapshot-id $snapshot_id
        done
    fi
    
    echo "  ✅ Snapshots cleaned up"
done

echo "🎉 Cleanup completed!"
EOF

chmod +x scripts/cleanup-old-amis.sh
```

### 4. Usage Examples

```bash
# List all your custom AMIs
aws ec2 describe-images \
    --owners self \
    --filters 'Name=name,Values=market-database-*' \
    --query 'Images[*].{ImageId:ImageId,Name:Name,CreationDate:CreationDate,State:State}' \
    --output table

# Manual cleanup (keep 3 most recent)
./scripts/cleanup-old-amis.sh 3

# Aggressive cleanup (keep only 1 most recent)
./scripts/cleanup-old-amis.sh 1

# Delete specific AMI manually
aws ec2 deregister-image --image-id ami-xxxxxxxxx

# Find and delete associated snapshots
aws ec2 describe-snapshots \
    --owner-ids self \
    --filters 'Name=description,Values=*ami-xxxxxxxxx*' \
    --query 'Snapshots[*].SnapshotId' \
    --output text | xargs -n1 aws ec2 delete-snapshot --snapshot-id
```

### 5. Cost Monitoring

Track AMI storage costs:
```bash
# Calculate total storage cost for your AMIs
aws ec2 describe-images \
    --owners self \
    --filters 'Name=name,Values=market-database-*' \
    --query 'sum(Images[*].BlockDeviceMappings[0].Ebs.VolumeSize)' \
    --output text | awk '{printf "Total storage: %d GB (~$%.2f/month)\n", $1, $1*0.05}'

# List storage per AMI
aws ec2 describe-images \
    --owners self \
    --filters 'Name=name,Values=market-database-*' \
    --query 'Images[*].{Name:Name,SizeGB:BlockDeviceMappings[0].Ebs.VolumeSize,MonthlyCost:BlockDeviceMappings[0].Ebs.VolumeSize}' \
    --output table
```

## Troubleshooting

### Common Build Issues

| **Problem** | **Symptoms** | **Solution** |
|-------------|--------------|-------------|
| **Packer timeout** | Build hangs or times out | Increase instance type to `t3.small` or add `--debug` flag |
| **AWS permissions** | `UnauthorizedOperation` errors | Verify IAM permissions include all EC2 actions |
| **Docker pull fails** | Images not found in AMI | Check internet connectivity during build |
| **Service won't start** | Containers not running after boot | Verify systemd service configuration |

### Debugging Commands

```bash
# Debug Packer build process
packer build -debug -on-error=ask packer/database-ami.pkr.hcl

# Verify AWS access
aws sts get-caller-identity
aws ec2 describe-regions --region ap-southeast-1

# Check build instance connectivity
# (Use the SSH command provided by Packer during debug build)
ssh -i /tmp/packer_key ubuntu@<build-instance-ip>

# Validate AMI after creation
aws ec2 describe-images --image-ids ami-xxxxxxxxx --output table
```

### Runtime Troubleshooting

```bash
# SSH to instance using custom AMI
ssh -i your-key.pem ubuntu@<instance-ip>

# Check database service status
sudo systemctl status database-services.service
sudo journalctl -u database-services.service -f

# Verify Docker containers
sudo docker ps -a
sudo docker logs market_mysql
sudo docker logs market_redis

# Check network connectivity
sudo docker exec market_mysql mysqladmin ping -h localhost
sudo docker exec market_redis redis-cli ping
```

## Security & Best Practices

### 🔒 Security Checklist

- [ ] **Regular AMI updates** (monthly security patches)
- [ ] **Image vulnerability scanning** (AWS Inspector or third-party)
- [ ] **Least privilege IAM** (minimal required permissions)
- [ ] **Encrypted EBS snapshots** (default in modern regions)
- [ ] **Private AMI sharing** (don't make AMIs public)

### 🏗️ Production Recommendations

1. **Container Registry**: Use Amazon ECR instead of Docker Hub
2. **Image Scanning**: Implement automated vulnerability scanning
3. **Configuration Management**: Use AWS Systems Manager Parameter Store
4. **Monitoring**: Add CloudWatch logs and metrics
5. **Backup Strategy**: Regular AMI snapshots with retention policies

### 💡 Cost Optimization Tips

- **Right-size build instances** (`t3.micro` sufficient for most cases)
- **Cleanup old AMIs regularly** (use provided script)
- **Use gp3 EBS volumes** (more cost-effective than gp2)
- **Monitor snapshot storage** (grows with AMI versions)

## Quick Reference

### Essential Commands
```bash
# Build new AMI
./packer/build-ami.sh

# List AMIs
aws ec2 describe-images --owners self --filters 'Name=name,Values=market-database-*'

# Cleanup old AMIs (keep 3)
./scripts/cleanup-old-amis.sh 3

# Calculate storage costs
aws ec2 describe-images --owners self --filters 'Name=name,Values=market-database-*' \
    --query 'sum(Images[*].BlockDeviceMappings[0].Ebs.VolumeSize)' | \
    awk '{printf "Storage: %d GB (~$%.2f/month)\n", $1, $1*0.05}'
```

### File Structure
```
terraform/examples/02-market-practice/
├── packer/
│   ├── database-ami.pkr.hcl       # Packer configuration
│   └── build-ami.sh               # Build script
├── scripts/
│   └── cleanup-old-amis.sh        # AMI lifecycle management
├── user-data/
│   ├── database.sh                # Standard Ubuntu setup
│   └── database-custom.sh         # Custom AMI startup
└── docs/
    └── custom-ami-guide.md        # This guide
```

---

**💡 Pro Tip**: Set up a monthly calendar reminder to rebuild your AMIs for security updates and run the cleanup script to manage costs.