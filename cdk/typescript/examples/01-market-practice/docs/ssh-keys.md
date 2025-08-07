# SSH Keys Setup

This document explains how to set up SSH keys for accessing the instances in your market practice environment.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions
- SSH client installed on your local machine

## Creating an SSH Key Pair

There are two approaches for setting up SSH keys:

### Option 1: Create a key pair in the AWS Console

1. Navigate to the EC2 dashboard in the AWS Console
2. Click on "Key Pairs" in the left navigation menu
3. Click "Create key pair"
4. Enter a name (e.g., "market-practice-key")
5. Select the key pair format (PEM for OpenSSH, or PPK for PuTTY)
6. Click "Create key pair"
7. The private key file will automatically download
8. Save this file securely on your computer

### Option 2: Import an existing SSH key

1. Generate an SSH key pair on your local machine if you don't have one:
   ```bash
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/market-practice-key
   ```

2. Navigate to the EC2 dashboard in the AWS Console
3. Click on "Key Pairs" in the left navigation menu
4. Click "Import key pair"
5. Enter a name (e.g., "market-practice-key")
6. Upload your public key file or paste its content
7. Click "Import key pair"

## Using the key with CDK

1. Update your `cdk.context.json` file with the key name:
   ```json
   {
     "key_name": "market-practice-key"
   }
   ```

2. Deploy your CDK stack:
   ```bash
   cdk deploy
   ```

## Connecting to Instances

### Connecting to the Bastion Host

After deployment, use the SSH command output from the CDK stack:

```bash
ssh -i ~/.ssh/market-practice-key.pem ubuntu@<bastion-public-ip>
```

### Connecting to Other Instances via the Bastion

Once connected to the bastion host, you can use the pre-configured SSH aliases:

```bash
# Connect to webapp
ssh webapp

# Connect to database
ssh database
```

## Troubleshooting

- **Permission errors**: Ensure your key file has the correct permissions:
  ```bash
  chmod 400 ~/.ssh/market-practice-key.pem
  ```

- **Connection timeout**: Check that the security group allows SSH from your IP address

- **Key not found**: Make sure the key name in cdk.context.json matches the name you used when creating/importing the key pair in AWS