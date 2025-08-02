#!/bin/bash

# AWS Infrastructure Cleanup Script
# This script helps identify and clean up resources to avoid unexpected costs

set -e

echo "🧹 AWS Infrastructure Cleanup Script"
echo "===================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured or credentials are invalid"
    echo "Please run 'aws configure' first"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
REGION=$(aws configure get region || echo "us-east-1")

echo "🔍 Account: $ACCOUNT_ID"
echo "🌍 Region: $REGION"
echo ""

# Function to check and destroy terraform resources in sandbox
cleanup_terraform_sandbox() {
    echo "🔍 Checking Terraform sandbox directories..."
    
    find . -path "*/sandbox/*" -name "*.tfstate" -type f | while read tfstate_file; do
        dir=$(dirname "$tfstate_file")
        echo "📁 Found Terraform state in: $dir"
        
        cd "$dir"
        if [ -f "terraform.tfstate" ] && [ -s "terraform.tfstate" ]; then
            echo "💥 Destroying resources in $dir"
            terraform destroy -auto-approve || echo "⚠️  Failed to destroy resources in $dir"
        fi
        cd - > /dev/null
    done
}

# Function to list EC2 instances with sandbox tags
list_sandbox_ec2() {
    echo "🖥️  Checking for sandbox EC2 instances..."
    
    instances=$(aws ec2 describe-instances \
        --filters "Name=tag:Environment,Values=sandbox" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name,Name:Tags[?Key==`Name`].Value|[0]}' \
        --output table)
    
    if [[ "$instances" == *"InstanceId"* ]]; then
        echo "$instances"
        echo ""
        read -p "🚨 Found sandbox EC2 instances. Terminate them? (y/N): " confirm
        if [[ $confirm == [yY] ]]; then
            aws ec2 describe-instances \
                --filters "Name=tag:Environment,Values=sandbox" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
                --query 'Reservations[].Instances[].InstanceId' \
                --output text | xargs -r aws ec2 terminate-instances --instance-ids
            echo "✅ EC2 instances termination initiated"
        fi
    else
        echo "✅ No sandbox EC2 instances found"
    fi
}

# Function to list RDS instances with sandbox tags
list_sandbox_rds() {
    echo "🗄️  Checking for sandbox RDS instances..."
    
    rds_instances=$(aws rds describe-db-instances \
        --query 'DBInstances[?contains(TagList[?Key==`Environment`].Value, `sandbox`)].{DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceStatus:DBInstanceStatus}' \
        --output table 2>/dev/null || echo "No RDS instances")
    
    if [[ "$rds_instances" == *"DBInstanceIdentifier"* ]]; then
        echo "$rds_instances"
        echo "⚠️  Found sandbox RDS instances. Please delete them manually from AWS Console"
        echo "   (Automated deletion disabled to prevent accidental data loss)"
    else
        echo "✅ No sandbox RDS instances found"
    fi
}

# Function to list S3 buckets with sandbox tags
list_sandbox_s3() {
    echo "🪣 Checking for sandbox S3 buckets..."
    
    aws s3api list-buckets --query 'Buckets[].Name' --output text | while read bucket; do
        if aws s3api get-bucket-tagging --bucket "$bucket" 2>/dev/null | grep -q "sandbox"; then
            echo "📦 Found sandbox bucket: $bucket"
            read -p "🚨 Delete bucket $bucket and all contents? (y/N): " confirm
            if [[ $confirm == [yY] ]]; then
                aws s3 rm "s3://$bucket" --recursive
                aws s3 rb "s3://$bucket"
                echo "✅ Deleted bucket: $bucket"
            fi
        fi
    done
}

# Function to check CloudFormation stacks
list_sandbox_cloudformation() {
    echo "📚 Checking for sandbox CloudFormation stacks..."
    
    stacks=$(aws cloudformation describe-stacks \
        --query 'Stacks[?contains(Tags[?Key==`Environment`].Value, `sandbox`)].{StackName:StackName,StackStatus:StackStatus}' \
        --output table 2>/dev/null || echo "No stacks")
    
    if [[ "$stacks" == *"StackName"* ]]; then
        echo "$stacks"
        echo "⚠️  Found sandbox CloudFormation stacks. Please delete them manually from AWS Console"
        echo "   (Automated deletion disabled to prevent dependency issues)"
    else
        echo "✅ No sandbox CloudFormation stacks found"
    fi
}

# Function to estimate costs
estimate_costs() {
    echo "💰 Estimating costs for the last 7 days..."
    
    end_date=$(date +%Y-%m-%d)
    start_date=$(date -d '7 days ago' +%Y-%m-%d)
    
    cost=$(aws ce get-cost-and-usage \
        --time-period Start="$start_date",End="$end_date" \
        --granularity DAILY \
        --metrics BlendedCost \
        --query 'ResultsByTime[].Total.BlendedCost.Amount' \
        --output text | awk '{sum+=$1} END {printf "%.2f", sum}')
    
    echo "💸 Total cost (last 7 days): \$$cost USD"
    
    if (( $(echo "$cost > 5.00" | bc -l) )); then
        echo "⚠️  Cost is above \$5. Consider reviewing and cleaning up resources."
    else
        echo "✅ Cost is within reasonable limits."
    fi
}

# Main execution
echo "Starting cleanup process..."
echo ""

cleanup_terraform_sandbox
echo ""
list_sandbox_ec2
echo ""
list_sandbox_rds
echo ""
list_sandbox_s3
echo ""
list_sandbox_cloudformation
echo ""
estimate_costs

echo ""
echo "🎉 Cleanup process completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Review any remaining resources in AWS Console"
echo "   2. Set up billing alerts if not already configured"
echo "   3. Remember to always destroy resources after experimentation"
echo ""
echo "💡 Pro tip: Use 'aws configure set region us-east-1' to set your default region"