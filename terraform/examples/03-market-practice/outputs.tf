# Infrastructure Outputs
output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "app_vpc_id" {
  description = "ID of the application VPC"
  value       = module.app_vpc.vpc_id
}

output "bastion_vpc_id" {
  description = "ID of the bastion VPC (staging only)"
  value       = local.current_env.enable_bastion ? module.bastion_vpc[0].vpc_id : null
}

# Instance Outputs
output "webapp_public_ip" {
  description = "Public IP of webapp server"
  value       = module.webapp.public_ip
}

output "webapp_url" {
  description = "URL to access the webapp"
  value       = "http://${module.webapp.public_ip}"
}

output "glances_url" {
  description = "URL to access Glances monitoring"
  value       = "http://${module.webapp.public_ip}:61208"
}

output "bastion_public_ip" {
  description = "Public IP of bastion host (staging only)"
  value       = local.current_env.enable_bastion ? module.bastion[0].public_ip : null
}

# Database service outputs (RDS and ElastiCache)
output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "database_info" {
  description = "Database connection information"
  value = {
    mysql_endpoint = aws_db_instance.main.endpoint
    mysql_port     = aws_db_instance.main.port
    mysql_database = aws_db_instance.main.db_name
    redis_endpoint = aws_elasticache_replication_group.main.primary_endpoint_address
    redis_port     = aws_elasticache_replication_group.main.port
  }
}

# SSH Key Outputs
output "private_key_path" {
  description = "Path to the generated private key file"
  value       = local_file.private_key.filename
}

output "key_pair_name" {
  description = "Name of the generated key pair"
  value       = aws_key_pair.market_practice.key_name
}

output "ssh_commands" {
  description = "SSH commands using generated key"
  value = local.current_env.enable_bastion ? {
    # Staging: Secure access via bastion
    bastion = "ssh -i ${local_file.private_key.filename} ubuntu@${module.bastion[0].public_ip}"
    
# SSH Commands (copy without the outer quotes)
    webapp_via_bastion = <<-EOT
      ssh -i ${local_file.private_key.filename} -o ProxyCommand="ssh -i ${local_file.private_key.filename} -o StrictHostKeyChecking=no -W %h:%p ubuntu@${module.bastion[0].public_ip}" -o StrictHostKeyChecking=no ubuntu@${module.webapp.private_ip}
    EOT
    
    database_connection_info = "Use database_info output for RDS and Redis connection details"
    
    detailed_guide = "See docs/ssh-access.md for complete SSH guide"
    emergency_note = "For emergency direct access, uncomment SSH rules in modules/security/main.tf"
  } : {
    # Production: No bastion access (emergency only)
    production_note = "Production is isolated - no SSH access by design"
    emergency_webapp = "For emergency access, uncomment SSH rules in modules/security/main.tf"
    database_note = "Using managed RDS and ElastiCache - no SSH access needed"
  }
}

# Network Configuration
output "vpc_peering_status" {
  description = "VPC peering connection status"
  value       = local.current_env.enable_vpc_peering ? "Enabled" : "Disabled"
}

output "network_configuration" {
  description = "Network configuration details"
  value = {
    environment        = var.environment
    app_vpc_cidr       = local.current_env.vpc_cidr
    bastion_vpc_cidr   = local.current_env.enable_bastion ? local.bastion_vpc_cidr : null
    public_subnet      = local.current_env.public_subnet
    private_subnet     = local.current_env.private_subnet
    has_bastion        = local.current_env.enable_bastion
    vpc_peering        = local.current_env.enable_vpc_peering
    security_model     = local.current_env.enable_bastion ? "bastion-only-access" : "production-isolated"
  }
}

