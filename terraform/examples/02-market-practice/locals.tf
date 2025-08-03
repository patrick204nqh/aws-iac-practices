# Local values for consistent naming and tagging
locals {
  # Naming convention: project-environment-resource
  name_prefix = "market-${var.environment}"
  
  # Common tags applied to all resources
  common_tags = {
    Project     = "market-practice"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "devops-team"
    CostCenter  = "engineering"
  }

  # Environment-specific configurations
  env_config = {
    staging = {
      vpc_cidr           = "10.2.0.0/16"
      public_subnet      = "10.2.1.0/24"
      private_subnet     = "10.2.2.0/24"
      enable_bastion     = true   # Staging has bastion for development access
      enable_vpc_peering = true   # Staging allows VPC peering
      enable_nat_gateway = false  # Staging doesn't need NAT gateway (cost optimization + custom AMI)
      database_ami_type  = "custom"  # Use custom AMI for cost optimization
      database_user_data = "database-custom.sh"
      instance_sizes     = {
        webapp   = "t3.micro"
        database = "t3.micro"
        bastion  = "t3.micro"
      }
    }
    prod = {
      vpc_cidr           = "10.0.0.0/16"
      public_subnet      = "10.0.1.0/24"
      private_subnet     = "10.0.2.0/24"
      enable_bastion     = false  # Production has no bastion (completely isolated)
      enable_vpc_peering = false  # Production has no VPC peering
      enable_nat_gateway = true   # Production needs NAT gateway for private subnet internet access
      database_ami_type  = "ubuntu"  # Use standard Ubuntu AMI
      database_user_data = "database.sh"
      instance_sizes     = {
        webapp   = "t3.small"
        database = "t3.small"
        bastion  = null  # No bastion in production
      }
    }
  }

  # Get current environment config
  current_env = local.env_config[var.environment]
  
  # Bastion VPC configuration (shared across environments)
  bastion_vpc_cidr = "10.1.0.0/16"
  bastion_subnet   = "10.1.1.0/24"
}