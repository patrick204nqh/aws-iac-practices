# Sandbox Guide

## What is the Sandbox?

The sandbox directories are your personal playground for AWS experiments. Unlike examples (which should stay clean) or projects (which should be complete), sandbox is where you:

- 🧪 Try crazy ideas
- 💥 Break things safely
- 🎨 Experiment freely
- 📝 Take messy notes

## Sandbox Rules

1. **ALWAYS DESTROY RESOURCES** when done
2. **Don't commit sensitive data** (use .gitignore)
3. **Tag everything** with `Environment: sandbox`
4. **Document your learning** (even if messy)

## Sandbox vs Examples vs Projects

| Aspect | Examples | Sandbox | Projects |
|--------|----------|---------|----------|
| Purpose | Learn concepts | Experiment | Build portfolio |
| Quality | Clean, working | Messy OK | Production-ready |
| Commits | Careful commits | Commit anything | Professional commits |
| Lifecycle | Preserve as reference | Delete often | Long-lived |
| Documentation | Tutorial style | Personal notes | Professional docs |

## Typical Sandbox Workflow

```bash
# 1. Create experiment
cd terraform/sandbox/
mkdir trying-asg-with-alb
cd trying-asg-with-alb

# 2. Copy from example as starting point
cp -r ../../examples/02-vpc-networking/* .

# 3. Hack away!
# - Change things
# - Break things  
# - Learn things

# 4. Take notes
echo "Learned that security groups need..." >> NOTES.md

# 5. DESTROY EVERYTHING
terraform destroy -auto-approve

# 6. Decide what to do
# - Move learnings to a clean example?
# - Create a proper project?
# - Just delete and move on?
```

## Sandbox Organization Ideas

```
sandbox/
├── README.md
├── 2024-01-15-vpc-peering/     # Date-based
├── trying-fargate/              # Topic-based
├── debug-sg-issue/              # Problem-solving
├── cost-optimization-test/      # Experimentation
└── archived/                    # Old experiments
    └── 2023-12-old-stuff/
```

## Cost Control in Sandbox

```hcl
# Always add to your sandbox terraform files:

locals {
  common_tags = {
    Environment = "sandbox"
    Project     = "aws-iac-practices"
    AutoDelete  = "true"
    CreatedDate = timestamp()
  }
}

# Use auto-termination for EC2
resource "aws_instance" "sandbox" {
  # ... other config ...
  
  # Auto-terminate after 2 hours
  user_data = <<-EOF
    #!/bin/bash
    echo "sudo shutdown -h +120" | at now
  EOF
  
  tags = local.common_tags
}
```

## What to Build in Sandbox?

### Beginner Experiments
- [ ] Launch EC2 in custom VPC
- [ ] Create S3 bucket with versioning
- [ ] Set up RDS with read replica
- [ ] Configure ALB with target groups

### Intermediate Experiments
- [ ] VPC peering between regions
- [ ] Lambda with API Gateway
- [ ] ECS Fargate service
- [ ] Step Functions workflow

### Advanced Experiments
- [ ] Multi-region active-active setup
- [ ] Service mesh with App Mesh
- [ ] GitOps with Flux/ArgoCD
- [ ] Chaos engineering setup

## Remember!

> "The sandbox is where you learn by doing. Break things, fix them, break them again. Just remember to clean up after yourself!" 🧹