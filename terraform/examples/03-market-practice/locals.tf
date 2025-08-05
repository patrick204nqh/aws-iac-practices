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
      vpc_cidr                   = "10.2.0.0/16"
      public_subnet              = "10.2.1.0/24"
      private_subnet             = "10.2.2.0/24"
      db_private_subnet_secondary = "10.2.3.0/24"
      enable_bastion             = true   # Staging has bastion for development access
      enable_vpc_peering         = true   # Staging allows VPC peering
      instance_sizes             = {
        webapp  = "t3.micro"
        bastion = "t3.micro"
      }
      # RDS Configuration
      rds_instance_class         = "db.t3.micro"
      rds_allocated_storage      = 20
      rds_max_allocated_storage  = 50
      rds_backup_retention       = 1
      rds_deletion_protection    = false
      # Redis Configuration
      redis_node_type            = "cache.t3.micro"
      redis_num_cache_nodes      = 1
      redis_automatic_failover   = false
      redis_multi_az             = false
      redis_snapshot_retention   = 1
    }
    prod = {
      vpc_cidr                   = "10.0.0.0/16"
      public_subnet              = "10.0.1.0/24"
      private_subnet             = "10.0.2.0/24"
      db_private_subnet_secondary = "10.0.3.0/24"
      enable_bastion             = false  # Production has no bastion (completely isolated)
      enable_vpc_peering         = false  # Production has no VPC peering
      instance_sizes             = {
        webapp  = "t3.small"
        bastion = null  # No bastion in production
      }
      # RDS Configuration
      rds_instance_class         = "db.t3.small"
      rds_allocated_storage      = 50
      rds_max_allocated_storage  = 100
      rds_backup_retention       = 7
      rds_deletion_protection    = true
      # Redis Configuration
      redis_node_type            = "cache.t3.small"
      redis_num_cache_nodes      = 2
      redis_automatic_failover   = true
      redis_multi_az             = true
      redis_snapshot_retention   = 5
    }
  }

  # Get current environment config
  current_env = local.env_config[var.environment]
  
  # Bastion VPC configuration (shared across environments)
  bastion_vpc_cidr = "10.1.0.0/16"
  bastion_subnet   = "10.1.1.0/24"
}