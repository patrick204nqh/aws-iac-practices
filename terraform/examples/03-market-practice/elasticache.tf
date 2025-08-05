# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-cache-subnet-group"
  subnet_ids = [module.app_vpc.private_subnet_id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cache-subnet-group"
  })
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  family = "redis7"
  name   = "${local.name_prefix}-cache-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cache-params"
  })
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${local.name_prefix}-redis"
  description                = "Redis cluster for ${local.name_prefix}"

  # Node configuration
  node_type            = local.current_env.redis_node_type
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.main.name

  # Cluster configuration
  num_cache_clusters = local.current_env.redis_num_cache_nodes

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [module.app_security.redis_security_group_id]

  # Security configuration
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false  # Disabled for simplicity in development
  auth_token_enabled         = false  # Disabled for simplicity in development

  # Backup configuration
  automatic_failover_enabled = local.current_env.redis_automatic_failover
  multi_az_enabled          = local.current_env.redis_multi_az
  snapshot_retention_limit  = local.current_env.redis_snapshot_retention
  snapshot_window          = "03:00-05:00"

  # Maintenance
  maintenance_window = "sun:05:00-sun:07:00"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis"
  })
}