# SSH Key Pair

This example automatically generates SSH key pairs - no manual setup required.

## How It Works

1. **Generate**: Creates RSA 4096-bit key pair automatically
2. **Register**: Adds public key to AWS with unique name
3. **Save**: Stores private key as `market-practice-key.pem` locally
4. **Use**: SSH commands provided in terraform outputs

## Files Created

- `market-practice-key.pem` - Private key file (600 permissions)
- AWS key pair: `market-practice-<random>` 

## Usage

```bash
# Get SSH commands
terraform output ssh_commands

# Example output:
ssh -i ./market-practice-key.pem ubuntu@<bastion-ip>
```

## Security

- ✅ Strong 4096-bit RSA encryption
- ✅ Correct file permissions (600) set automatically  
- ✅ Unique naming prevents conflicts
- ✅ Clean removal with `terraform destroy`

## Important

- Add `*.pem` to `.gitignore`
- Private key only exists locally
- Each deployment gets unique keys