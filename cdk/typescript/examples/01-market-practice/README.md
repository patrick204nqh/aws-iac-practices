# AWS CDK Market Practice Example

This example recreates the Terraform market practice example using AWS CDK (TypeScript).

## Project Structure

```
cdk/typescript/examples/01-market-practice/
├── bin/                  # CDK application entry point
├── lib/                  # CDK stack definitions
├── user-data/            # EC2 instance user data scripts
├── docs/                 # Documentation
├── cdk.json              # CDK configuration
├── package.json          # Project dependencies
├── tsconfig.json         # TypeScript configuration
├── cdk.context.json      # Project context (created from example)
├── cdk.context.json.example  # Example context file
└── README.md             # Project overview
```

## Infrastructure Overview

This example creates:

- Two VPCs (Production and Bastion) with VPC Peering
- EC2 instances for web application, database, and bastion host
- Security groups for proper network isolation
- User data scripts for automatic provisioning

## Prerequisites

- [Node.js](https://nodejs.org/) (>= 14.x)
- [AWS CDK](https://aws.amazon.com/cdk/) installed (`npm install -g aws-cdk`)
- AWS CLI configured with appropriate permissions
- SSH key pair in AWS (see docs/ssh-keys.md for details)

## Getting Started

1. Install dependencies:
```bash
npm install
```

2. Configure the project:
```bash
cp cdk.context.json.example cdk.context.json
# Edit cdk.context.json with your specific values
```

3. Bootstrap CDK (first time only):
```bash
cdk bootstrap
```

4. Deploy the stack:
```bash
cdk deploy
```

## Documentation

- [Architecture Overview](docs/architecture.md)
- [SSH Keys Setup](docs/ssh-keys.md)
- [Backend Setup](docs/backend-setup.md)

## Cleanup

To remove all resources created by this example:

```bash
cdk destroy
```

## License

This example is provided under the MIT license.