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