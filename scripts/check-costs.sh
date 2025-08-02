#!/bin/bash

# AWS Cost Monitoring Script
# This script helps monitor AWS costs and identify expensive resources

set -e

echo "💰 AWS Cost Monitoring Script"
echo "============================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured or credentials are invalid"
    echo "Please run 'aws configure' first"
    exit 1
fi

# Check if bc is installed for calculations
if ! command -v bc &> /dev/null; then
    echo "⚠️  'bc' calculator not found. Installing recommendations:"
    echo "   Ubuntu/Debian: sudo apt-get install bc"
    echo "   macOS: brew install bc"
    echo "   Using basic calculations instead..."
    USE_BC=false
else
    USE_BC=true
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
REGION=$(aws configure get region || echo "us-east-1")

echo "🔍 Account: $ACCOUNT_ID"
echo "🌍 Region: $REGION"
echo ""

# Function to get cost for specific time period
get_costs() {
    local start_date=$1
    local end_date=$2
    local period_name=$3
    
    echo "📊 $period_name costs:"
    
    # Get total cost
    total_cost=$(aws ce get-cost-and-usage \
        --time-period Start="$start_date",End="$end_date" \
        --granularity DAILY \
        --metrics BlendedCost \
        --query 'ResultsByTime[].Total.BlendedCost.Amount' \
        --output text | awk '{sum+=$1} END {printf "%.2f", sum}')
    
    echo "   Total: \$$total_cost USD"
    
    # Get cost by service
    echo "   Top services:"
    aws ce get-cost-and-usage \
        --time-period Start="$start_date",End="$end_date" \
        --granularity DAILY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'ResultsByTime[0].Groups[?Total.BlendedCost.Amount>`0.01`].{Service:Keys[0],Cost:Total.BlendedCost.Amount}' \
        --output table | head -10
    
    echo ""
    
    # Return total cost for comparison
    echo "$total_cost"
}

# Function to check current month projection
check_monthly_projection() {
    echo "📈 Monthly cost projection:"
    
    # Get current month start and today
    current_month_start=$(date +%Y-%m-01)
    today=$(date +%Y-%m-%d)
    month_end=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%Y-%m-%d)
    
    # Get cost so far this month
    month_cost=$(aws ce get-cost-and-usage \
        --time-period Start="$current_month_start",End="$today" \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
        --output text)
    
    if [ "$month_cost" != "None" ] && [ -n "$month_cost" ]; then
        # Calculate days elapsed and remaining
        days_elapsed=$(( ( $(date -d "$today" +%s) - $(date -d "$current_month_start" +%s) ) / 86400 ))
        days_in_month=$(( ( $(date -d "$month_end" +%s) - $(date -d "$current_month_start" +%s) ) / 86400 + 1 ))
        
        echo "   Current month so far: \$$month_cost USD ($days_elapsed days)"
        
        if [ "$USE_BC" == true ] && [ "$days_elapsed" -gt 0 ]; then
            daily_average=$(echo "scale=2; $month_cost / $days_elapsed" | bc)
            projected_total=$(echo "scale=2; $daily_average * $days_in_month" | bc)
            echo "   Projected monthly total: \$$projected_total USD"
            
            # Warning if projection is high
            if (( $(echo "$projected_total > 10.00" | bc -l) )); then
                echo "   ⚠️  Projected cost is above \$10/month!"
            fi
        fi
    else
        echo "   No cost data available for current month yet"
    fi
    
    echo ""
}

# Function to identify expensive resources
identify_expensive_resources() {
    echo "🎯 Identifying potentially expensive resources:"
    
    # Check for running EC2 instances
    echo "   EC2 Instances:"
    instances=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].{InstanceId:InstanceId,InstanceType:InstanceType,Name:Tags[?Key==`Name`].Value|[0]}' \
        --output table)
    
    if [[ "$instances" == *"InstanceId"* ]]; then
        echo "$instances"
    else
        echo "      ✅ No running EC2 instances"
    fi
    
    echo ""
    
    # Check for RDS instances
    echo "   RDS Instances:"
    rds_instances=$(aws rds describe-db-instances \
        --query 'DBInstances[?DBInstanceStatus==`available`].{DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceClass:DBInstanceClass,Engine:Engine}' \
        --output table 2>/dev/null || echo "      ✅ No RDS instances")
    
    if [[ "$rds_instances" == *"DBInstanceIdentifier"* ]]; then
        echo "$rds_instances"
    else
        echo "      ✅ No RDS instances"
    fi
    
    echo ""
    
    # Check for NAT Gateways
    echo "   NAT Gateways:"
    nat_gateways=$(aws ec2 describe-nat-gateways \
        --filter "Name=state,Values=available" \
        --query 'NatGateways[].{NatGatewayId:NatGatewayId,SubnetId:SubnetId,State:State}' \
        --output table 2>/dev/null || echo "      ✅ No NAT Gateways")
    
    if [[ "$nat_gateways" == *"NatGatewayId"* ]]; then
        echo "$nat_gateways"
        echo "      ⚠️  NAT Gateways cost ~\$45/month each"
    else
        echo "      ✅ No NAT Gateways"
    fi
    
    echo ""
    
    # Check for Load Balancers
    echo "   Load Balancers:"
    load_balancers=$(aws elbv2 describe-load-balancers \
        --query 'LoadBalancers[].{LoadBalancerName:LoadBalancerName,Type:Type,State:State.Code}' \
        --output table 2>/dev/null || echo "      ✅ No Load Balancers")
    
    if [[ "$load_balancers" == *"LoadBalancerName"* ]]; then
        echo "$load_balancers"
        echo "      ⚠️  Application Load Balancers cost ~\$22/month each"
    else
        echo "      ✅ No Load Balancers"
    fi
    
    echo ""
}

# Function to check for untagged resources
check_untagged_resources() {
    echo "🏷️  Checking for untagged resources (potential cost leaks):"
    
    # Untagged EC2 instances
    untagged_ec2=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running,stopped" \
        --query 'Reservations[].Instances[?length(Tags)==`0`].InstanceId' \
        --output text)
    
    if [ -n "$untagged_ec2" ] && [ "$untagged_ec2" != "None" ]; then
        echo "   ⚠️  Untagged EC2 instances: $untagged_ec2"
    else
        echo "   ✅ All EC2 instances are tagged"
    fi
    
    # Check for S3 buckets without proper tagging
    echo "   Checking S3 buckets for cost allocation tags..."
    bucket_count=0
    untagged_count=0
    
    aws s3api list-buckets --query 'Buckets[].Name' --output text | while read bucket; do
        if [ -n "$bucket" ]; then
            bucket_count=$((bucket_count + 1))
            if ! aws s3api get-bucket-tagging --bucket "$bucket" 2>/dev/null | grep -q "Project\|Environment"; then
                echo "   ⚠️  Bucket lacks cost tags: $bucket"
                untagged_count=$((untagged_count + 1))
            fi
        fi
    done
    
    echo ""
}

# Function to provide cost optimization tips
provide_cost_tips() {
    echo "💡 Cost Optimization Tips:"
    echo "========================="
    echo ""
    echo "1. 🚀 Use Free Tier resources:"
    echo "   - t2.micro/t3.micro EC2 instances (750 hours/month)"
    echo "   - 20GB EBS storage"
    echo "   - 5GB S3 storage"
    echo ""
    echo "2. 🏷️  Always tag resources:"
    echo "   - Project: aws-iac-practices"
    echo "   - Environment: sandbox/dev/prod"
    echo "   - Owner: your-name"
    echo ""
    echo "3. 🧹 Clean up regularly:"
    echo "   - Stop EC2 instances when not in use"
    echo "   - Delete unused EBS volumes"
    echo "   - Remove old snapshots"
    echo ""
    echo "4. 📊 Set up billing alerts:"
    echo "   - Create budget alerts for \$5, \$10, \$20"
    echo "   - Monitor daily spend"
    echo ""
    echo "5. 🔄 Use automation:"
    echo "   - Auto-shutdown EC2 instances"
    echo "   - Scheduled cleanup scripts"
    echo "   - Infrastructure as Code (destroy after learning)"
}

# Main execution
echo "Starting cost analysis..."
echo ""

# Get costs for different periods
yesterday=$(date -d '1 day ago' +%Y-%m-%d)
today=$(date +%Y-%m-%d)
week_ago=$(date -d '7 days ago' +%Y-%m-%d)
month_ago=$(date -d '30 days ago' +%Y-%m-%d)

yesterday_cost=$(get_costs "$yesterday" "$today" "Yesterday")
week_cost=$(get_costs "$week_ago" "$today" "Last 7 days")
month_cost=$(get_costs "$month_ago" "$today" "Last 30 days")

check_monthly_projection
identify_expensive_resources
check_untagged_resources
provide_cost_tips

echo ""
echo "🎉 Cost analysis completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Review any high-cost resources identified above"
echo "   2. Set up AWS Budgets if not already configured"
echo "   3. Tag all resources for better cost tracking"
echo "   4. Run this script regularly to monitor costs"
echo ""
echo "🚨 Remember: Always destroy sandbox resources after experimentation!"