#!/bin/bash
set -e

echo "Building custom database AMI with pre-pulled Docker images..."

# Check if packer is installed
if ! command -v packer &> /dev/null; then
    echo "Error: Packer is not installed. Please install Packer first."
    echo "Visit: https://www.packer.io/downloads"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured or expired."
    echo "Please run: aws configure"
    exit 1
fi

# Build the AMI
echo "Starting Packer build..."
packer build \
    -var "aws_region=ap-southeast-1" \
    -var "instance_type=t3.micro" \
    -var "ami_name_prefix=market-database" \
    database-ami.pkr.hcl

echo "AMI build completed successfully!"
echo ""
echo "To find your new AMI ID, run:"
echo "aws ec2 describe-images --owners self --filters 'Name=name,Values=market-database-*' --query 'Images[0].ImageId' --output text"
echo ""
echo "Update the AMI ID in your Terraform data source and apply the changes."