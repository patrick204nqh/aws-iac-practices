# Testing Directory

This directory contains automated tests for our Infrastructure as Code.

## Structure

```
tests/
├── terraform/          # Terratest Go tests for Terraform modules
├── cdk/                # Jest/pytest tests for CDK constructs
└── README.md           # This file
```

## Running Tests

### Terraform Tests (Go + Terratest)

```bash
cd tests/terraform
go mod init aws-iac-tests
go mod tidy
go test -v ./...
```

### CDK TypeScript Tests

```bash
cd cdk/typescript
npm test
```

### CDK Python Tests

```bash
cd cdk/python
python -m pytest
```

## Test Philosophy

- **Unit tests**: Test individual modules in isolation
- **Integration tests**: Test multiple modules working together
- **End-to-end tests**: Test complete deployments
- **Always clean up**: Tests should destroy resources after validation

## Writing New Tests

See [docs/testing-strategy.md](../docs/testing-strategy.md) for detailed testing guidelines.