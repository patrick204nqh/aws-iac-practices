#!/bin/bash
set -e

AMI_PREFIX="market-database"

echo "🔍 Finding all custom AMIs to delete..."

# List all custom AMIs in table format
echo "📋 Custom AMIs found:"
aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=${AMI_PREFIX}-*" "Name=state,Values=available" \
    --query 'Images[*].{ImageId:ImageId,Name:Name,CreationDate:CreationDate}' \
    --output table

# Get AMI IDs for deletion
AMI_IDS=$(aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=${AMI_PREFIX}-*" "Name=state,Values=available" \
    --query 'Images[*].ImageId' \
    --output text)

if [ -z "$AMI_IDS" ]; then
    echo "✅ No custom AMIs found to delete"
    exit 0
fi

echo ""
read -p "🗑️  Delete ALL custom AMIs above? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ Cancelled"
    exit 0
fi

# Delete each AMI and its snapshots
for ami_id in $AMI_IDS; do
    echo "🗑️  Removing AMI: $ami_id"
    
    # Get snapshots before deregistering
    SNAPSHOTS=$(aws ec2 describe-images \
        --image-ids "$ami_id" \
        --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId!=`null`].Ebs.SnapshotId' \
        --output text 2>/dev/null || echo "")
    
    # Deregister AMI
    if aws ec2 deregister-image --image-id "$ami_id"; then
        echo "  ✅ AMI deregistered"
    else
        echo "  ❌ Failed to deregister $ami_id"
        continue
    fi
    
    # Delete snapshots
    if [ -n "$SNAPSHOTS" ] && [ "$SNAPSHOTS" != "None" ]; then
        for snapshot_id in $SNAPSHOTS; do
            echo "  🗑️  Deleting snapshot: $snapshot_id"
            aws ec2 delete-snapshot --snapshot-id "$snapshot_id" || echo "  ⚠️  Failed to delete snapshot"
        done
    fi
done

echo "🎉 All custom AMIs deleted!"