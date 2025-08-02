# Backend Setup

Terraform remote state with S3 backend and DynamoDB locking in **ap-southeast-1** (Singapore).

## Create Backend Resources

Run these commands once to set up the backend infrastructure:

```bash
# Create S3 bucket for state storage
aws s3 mb s3://terraform-state-aws-iac-practices --region ap-southeast-1

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket terraform-state-aws-iac-practices \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-southeast-1
```

## Verify Resources

```bash
# Check S3 bucket exists
aws s3 ls s3://terraform-state-aws-iac-practices

# Check DynamoDB table exists
aws dynamodb describe-table --table-name terraform-state-lock --region ap-southeast-1

# List available Ubuntu AMIs
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*" \
  --query 'Images[*].[Name,ImageId,CreationDate]' \
  --output table \
  --region ap-southeast-1
```

## Destroy Backend Resources

⚠️ **Warning**: Only run these commands after destroying all Terraform infrastructure that uses this backend.

```bash
# Delete all state files from S3 bucket
aws s3 rm s3://terraform-state-aws-iac-practices --recursive

# Delete S3 bucket
aws s3 rb s3://terraform-state-aws-iac-practices

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-state-lock --region ap-southeast-1
```

## Costs

- **S3**: ~$0.023/GB/month + requests
- **DynamoDB**: 5 RCU/WCU included in free tier
- **Total**: Usually under $1/month for examples