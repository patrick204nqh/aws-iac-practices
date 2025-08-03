# Environment-Specific Configurations

This folder contains environment-specific Terraform variable files following infrastructure best practices.

## Structure

```
environments/
├── staging/
│   └── terraform.tfvars    # Staging environment config
├── prod/
│   └── terraform.tfvars    # Production environment config
└── README.md              # This file
```

## Usage

Deploy to a specific environment using the `-var-file` flag:

```bash
# Deploy to staging
terraform plan -var-file=environments/staging/terraform.tfvars
terraform apply -var-file=environments/staging/terraform.tfvars

# Deploy to production
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

## Environment Differences

| Setting        | Staging            | Production            |
| -------------- | ------------------ | --------------------- |
| Environment    | `staging`          | `prod`                |
| VPC CIDR       | `10.2.0.0/16`      | `10.0.0.0/16`         |
| Instance Types | `t3.micro`         | `t3.small`            |
| Bastion Host   | ✅ Included         | ❌ Not deployed        |
| VPC Peering    | ✅ Enabled          | ❌ Disabled            |
| SSH Access     | Via bastion only   | Direct to webapp only |
| Security Model | Development access | Production isolation  |
| Resource Names | `market-staging-*` | `market-prod-*`       |

## Configuration

1. Copy the appropriate environment file
2. Update `my_ip` with your current IP address:
   ```bash
   curl ifconfig.me
   ```
3. Modify instance types if needed
4. Deploy using the `-var-file` flag

## Backend State

Each environment uses separate state files:
- Staging: `examples/02-market-practice/staging/terraform.tfstate`
- Production: `examples/02-market-practice/prod/terraform.tfstate`

Update `backend.tf` key based on environment or use Terraform workspaces.