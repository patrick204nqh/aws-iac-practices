# MCP Server Setup Guide

## What is MCP?

Model Context Protocol (MCP) servers provide enhanced context to Claude Code, enabling better assistance with AWS, Terraform, and GitHub operations.

## Setup Steps

### 1. Prerequisites

- Claude Code installed
- Docker installed and running
- AWS CLI configured
- GitHub personal access token
- direnv installed (recommended for environment variable management)

### 2. Docker Images

Pull the required MCP server Docker images:

```bash
# Pull official MCP server images
docker pull public.ecr.aws/awslabs-mcp/awslabs/nova-canvas-mcp-server:latest
docker pull hashicorp/terraform-mcp-server
docker pull ghcr.io/github/github-mcp-server
docker pull mcp/filesystem
docker pull mcp/fetch
```

### 3. Environment Variables Setup (with direnv)

**Install direnv** (if not already installed):
```bash
# Ubuntu/Debian
sudo apt install direnv

# macOS
brew install direnv

# Add to your shell (bash/zsh)
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc  # for bash
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc    # for zsh
```

**Setup environment variables**:
```bash
# Copy the example file
cp .envrc.example .envrc

# Edit with your actual values
nano .envrc

# Allow direnv to load the file
direnv allow
```

### 4. MCP Configuration

Copy `.mcp.json.example` to `.mcp.json` and update with your actual environment variables from `.envrc`:

```json
{
  "mcpServers": {
    "aws": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--env", "FASTMCP_LOG_LEVEL=ERROR",
        "--env", "AWS_REGION",
        "--env", "AWS_ACCESS_KEY_ID",
        "--env", "AWS_SECRET_ACCESS_KEY",
        "--env", "AWS_SESSION_TOKEN",
        "--volume", "${AWS_ABSOLUTE_PATH}:/app/.aws:ro",
        "public.ecr.aws/awslabs-mcp/awslabs/nova-canvas-mcp-server:latest"
      ]
    },
    "terraform": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--env", "TF_LOG",
        "--env", "AWS_REGION",
        "--env", "AWS_ACCESS_KEY_ID",
        "--env", "AWS_SECRET_ACCESS_KEY",
        "--env", "AWS_SESSION_TOKEN",
        "--volume", "${WORKSPACE_ABSOLUTE_PATH}:/workspace:ro",
        "--workdir", "/workspace",
        "hashicorp/terraform-mcp-server"
      ]
    },
    "github": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--env", "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ]
    },
    "filesystem": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--mount", "type=bind,src=${WORKSPACE_ABSOLUTE_PATH},dst=/projects/workspace",
        "mcp/filesystem",
        "/projects"
      ]
    },
    "fetch": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "mcp/fetch"
      ]
    }
  }
}
```

### 5. GitHub Token Setup

1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic) with scopes:
   - `repo` (full control)
   - `workflow` (if using GitHub Actions)
3. Copy token to `.mcp.json`

### 6. Security Notes

- **Never commit** `.mcp.json` or `.envrc` with real tokens
- Use direnv for automatic environment variable loading
- `.envrc` and `.mcp.json` are in `.gitignore` for security
- Environment variables are automatically passed to Docker containers

### 7. Verify Setup

In Claude Code, you should be able to:
- Query AWS resources directly
- Get Terraform suggestions
- Access GitHub repo information
- Navigate filesystem efficiently

## Troubleshooting

### MCP server not starting
```bash
# Check Docker is running
docker --version
docker ps

# Test server manually
docker run --rm -i public.ecr.aws/awslabs-mcp/awslabs/nova-canvas-mcp-server:latest
```

### AWS connection issues
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check AWS profile
export AWS_PROFILE=your-profile
```

## Available MCP Docker Images

### Official/Trusted Images
- `public.ecr.aws/awslabs-mcp/awslabs/nova-canvas-mcp-server:latest` - AWS resource management with AI canvas
- `hashicorp/terraform-mcp-server` - Terraform assistance
- `ghcr.io/github/github-mcp-server` - GitHub integration
- `mcp/filesystem` - File operations
- `mcp/fetch` - Web content fetching

### Docker Benefits
- **Isolation**: Each MCP server runs in its own container
- **Consistency**: Same environment across different machines
- **Easy Updates**: Pull new images when available
- **No Node.js dependency**: Docker handles runtime requirements

### Future Considerations
- `mcp/kubernetes-server` - Kubernetes management
- `mcp/docker-server` - Container operations
- Custom MCP servers for specific needs