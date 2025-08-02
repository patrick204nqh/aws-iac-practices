# AWS Infrastructure as Code Practices

Practice repository for AWS infrastructure automation with MCP server integration for enhanced Claude Code support.

## 🤖 MCP Servers Setup

This repo uses Model Context Protocol servers for better AI assistance:

1. **Install Claude Code** (if not already installed)
2. **Configure MCP servers** - Copy `.mcp.json.example` to `.mcp.json` and update with your tokens
3. **Supported servers**:
   - `public.ecr.aws/awslabs-mcp/awslabs/nova-canvas-mcp-server:latest` - AWS resource management with AI canvas
   - `hashicorp/terraform-mcp-server` - Terraform assistance  
   - `ghcr.io/github/github-mcp-server` - GitHub integration
   - `mcp/filesystem` - File operations
   - `mcp/fetch` - Web content fetching

See [docs/mcp-setup.md](docs/mcp-setup.md) for detailed setup.

## 📂 Repository Organization

### Learning Path Structure

```
📦 Tool (terraform/cdk/cloudformation)
├── 📚 examples/     # Follow tutorials here
├── 🧪 sandbox/      # Experiment freely here
├── 🏗️ projects/     # Build portfolio projects here
└── 🧰 modules/      # Create reusable components
```

### Where to Practice?

1. **Start Learning** → `examples/`
   - Follow numbered tutorials (01, 02, 03...)
   - Each has clear learning objectives
   - Always includes cleanup instructions

2. **Experiment** → `sandbox/`
   - Try wild ideas
   - Break things safely
   - No commit rules - it's your playground

3. **Build Portfolio** → `projects/`
   - Complete, production-like applications
   - Well-documented
   - Can show to employers

## 🎯 Practice Workflow

### For Each Learning Session

1. **Choose your focus**:
   ```bash
   cd terraform/examples/01-basic-ec2
   # or
   cd terraform/sandbox/my-experiment
   ```

2. **Initialize and plan**:
   ```bash
   terraform init
   terraform plan
   ```

3. **Deploy resources**:
   ```bash
   terraform apply
   ```

4. **ALWAYS DESTROY** when done:
   ```bash
   terraform destroy
   # or use the cleanup script
   ./destroy.sh
   ```

## 💰 Cost Management

### Golden Rules
1. **Tag Everything**: All resources must have `Project: aws-iac-practices`
2. **Use Free Tier**: Stick to free tier resources when possible
3. **Destroy Daily**: Never leave sandbox resources running overnight
4. **Set Budgets**: Create AWS Budget alerts ($5-10/month)

### Resource Cleanup
```bash
# Check what's running
./scripts/check-costs.sh

# Destroy all sandbox resources
./scripts/cleanup-resources.sh
```

## 🧪 Testing Strategy

### Manual Testing (Sandbox)
- Quick experiments
- Validation of concepts
- Breaking things to learn

### Automated Testing
- **Terraform**: Terratest in `tests/terraform/`
- **CDK**: Jest/pytest in respective directories
- Run before pushing to main

## 📝 Example: Your First Terraform Practice

1. **Start with example**:
   ```bash
   cd terraform/examples/01-basic-ec2
   cat README.md  # Read what you'll learn
   ```

2. **Try it out**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Experiment in sandbox**:
   ```bash
   cd ../../sandbox/
   mkdir my-ec2-experiment
   # Copy and modify the example
   # Try different instance types, add security groups, etc.
   ```

4. **Clean up**:
   ```bash
   terraform destroy  # ALWAYS DO THIS
   ```

## 🚀 Getting Started Checklist

- [ ] Clone repository
- [ ] Install direnv (`brew install direnv` or `sudo apt install direnv`)
- [ ] Set up AWS credentials
- [ ] Copy `.envrc.example` to `.envrc` and configure
- [ ] Copy `.mcp.json.example` to `.mcp.json` and configure
- [ ] Run `direnv allow` to load environment variables
- [ ] Create AWS Budget alert ($10 limit)
- [ ] Read `docs/sandbox-guide.md`
- [ ] Complete first example
- [ ] Create your first sandbox experiment

## 📚 Documentation

- [MCP Setup Guide](docs/mcp-setup.md)
- [Testing Strategy](docs/testing-strategy.md)
- [Sandbox Guidelines](docs/sandbox-guide.md)