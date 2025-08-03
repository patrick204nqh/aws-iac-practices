# Backend Setup

Terraform remote state with S3 backend in **ap-southeast-1** (Singapore).

## Create Backend Resources

Run these commands once to set up the backend infrastructure:

```bash
# Create S3 bucket for state storage
aws s3 mb s3://terraform-state-aws-iac-practices --region ap-southeast-1

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket terraform-state-aws-iac-practices \
  --versioning-configuration Status=Enabled

```

## Verify Resources

```bash
# Check S3 bucket exists
aws s3 ls s3://terraform-state-aws-iac-practices


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

```

## Costs

- **S3**: ~$0.023/GB/month + requests
- **Total**: Usually under $1/month for examples