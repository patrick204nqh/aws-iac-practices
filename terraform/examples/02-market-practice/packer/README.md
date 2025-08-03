# Packer Configuration for Custom Database AMI

This directory contains Packer configuration to build custom AMIs with pre-pulled Docker images.

## Quick Start

```bash
# 1. Initialize Packer (first time only)
packer init .

# 2. Build the AMI
./build-ami.sh
```

## Files

- **`database-ami.pkr.hcl`** - Packer configuration
- **`build-ami.sh`** - Build script

## Common Issues

### Plugin Missing Error
```
Error: Missing plugins
* github.com/hashicorp/amazon >= 1.2.8
```
**Solution**: Run `packer init .` first

### Build Options
```bash
# Debug mode
packer build -debug database-ami.pkr.hcl

# Custom variables
packer build -var "aws_region=us-west-2" database-ami.pkr.hcl
```

## Complete Documentation

See: `../docs/custom-ami-guide.md`