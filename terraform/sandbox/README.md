# Terraform Sandbox

This is your playground for Terraform experiments! 🎮

## What Goes Here?

- **Experiments**: Try new resource types, configurations, patterns
- **Learning**: Break things, fix them, learn from mistakes
- **Prototyping**: Test ideas before moving to examples or projects
- **Quick tests**: Validate concepts quickly

## Rules

1. **Always destroy resources** when done experimenting
2. **Tag everything** with `Environment = "sandbox"`
3. **Don't commit sensitive data** (use .gitignore)
4. **Document your learnings** (even messy notes are fine)

## Typical Workflow

```bash
# 1. Create new experiment directory
mkdir my-vpc-experiment
cd my-vpc-experiment

# 2. Copy from existing example (optional)
cp -r ../examples/01-basic-ec2/* .

# 3. Modify and experiment
# Edit main.tf, variables.tf, etc.

# 4. Test your changes
terraform init
terraform plan
terraform apply

# 5. ALWAYS clean up when done
terraform destroy -auto-approve

# 6. Document what you learned
echo "Learned: VPC endpoints reduce NAT gateway costs" >> NOTES.md
```

## Organization Ideas

```
sandbox/
├── vpc-peering-test/           # Testing VPC connectivity
├── rds-backup-strategy/        # Database backup experiments
├── lambda-api-gateway/         # Serverless experiments
├── cost-optimization/          # Testing cheaper alternatives
├── security-group-rules/       # Network security testing
└── archived/                   # Old experiments to reference
    └── 2024-01-old-experiments/
```

## Cost Control

Always include these tags in your experiments:

```hcl
locals {
  common_tags = {
    Environment = "sandbox"
    Project     = "aws-iac-practices"
    AutoDelete  = "true"
    Owner       = "your-name"
    CreatedDate = timestamp()
  }
}
```

## Quick Start Template

Create a new experiment with this basic structure:

```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Environment = "sandbox"
    Project     = "aws-iac-practices"
    AutoDelete  = "true"
    CreatedDate = timestamp()
  }
}

# Your resources here...
```

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```

## Remember

> The sandbox is where you learn by doing. Make mistakes, break things, and most importantly - **always clean up**! 🧹