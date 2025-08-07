# Backend Setup

This document explains how to set up the backend for your AWS CDK project using AWS S3 and DynamoDB for state management.

## Why Use a Remote Backend?

When working with Infrastructure as Code (IaC), it's important to store the state remotely to:

1. Enable team collaboration
2. Keep state history
3. Implement state locking to prevent concurrent modifications
4. Secure sensitive information

## Setting Up a Backend for AWS CDK

AWS CDK uses CloudFormation under the hood, which automatically manages state in AWS. However, for the CDK application itself, you may want to:

1. Store the CDK context in version control
2. Use environment-specific configurations
3. Set up a CI/CD pipeline

### Setting up cdk.context.json

1. Copy the example context file:
   ```bash
   cp cdk.context.json.example cdk.context.json
   ```

2. Update the values in cdk.context.json to match your environment:
   ```json
   {
     "aws_region": "ap-southeast-1",
     "my_ip": "YOUR_IP_ADDRESS/32",
     "enable_vpc_peering": true,
     "webapp_instance_type": "t3.micro",
     "database_instance_type": "t3.micro",
     "bastion_instance_type": "t3.micro",
     "key_name": "YOUR_KEY_NAME"
   }
   ```

   Replace:
   - `YOUR_IP_ADDRESS` with your public IP address (you can get this from https://whatismyip.com)
   - `YOUR_KEY_NAME` with the name of your SSH key pair in AWS

## Bootstrapping AWS CDK

Before deploying your first CDK application to an AWS environment, you need to bootstrap CDK:

```bash
cdk bootstrap aws://YOUR_ACCOUNT_ID/YOUR_REGION
```

Replace:
- `YOUR_ACCOUNT_ID` with your AWS account ID
- `YOUR_REGION` with your preferred AWS region (e.g., us-east-1)

## CDK Deployment

Once your backend is set up, you can deploy your infrastructure:

```bash
# Synthesize the CloudFormation template
cdk synth

# Preview changes before deployment
cdk diff

# Deploy the stack
cdk deploy
```

## Managing Multiple Environments

To manage multiple environments (e.g., dev, staging, prod), you can:

1. Create environment-specific context files:
   ```
   cdk.context.dev.json
   cdk.context.staging.json
   cdk.context.prod.json
   ```

2. Use the --context option to specify which environment to use:
   ```bash
   cdk deploy --context-from-file=cdk.context.dev.json
   ```

## Clean Up

To destroy the resources created by CDK:

```bash
cdk destroy
```