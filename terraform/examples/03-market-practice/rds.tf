# DB Subnet Group (requires at least 2 subnets in different AZs)
resource "aws_subnet" "db_private_secondary" {
  vpc_id            = module.app_vpc.vpc_id
  cidr_block        = local.current_env.db_private_subnet_secondary
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-private-secondary"
    Type = "private"
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [module.app_vpc.private_subnet_id, aws_subnet.db_private_secondary.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "${local.name_prefix}-db-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-params"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-mysql"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = local.current_env.rds_instance_class

  # Database configuration
  db_name  = "market_db"
  username = "admin"
  password = var.db_password

  # Storage configuration
  allocated_storage     = local.current_env.rds_allocated_storage
  max_allocated_storage = local.current_env.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.app_security.rds_security_group_id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = local.current_env.rds_backup_retention
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"

  # Performance configuration
  parameter_group_name = aws_db_parameter_group.main.name
  monitoring_interval  = 0

  # Deletion protection
  deletion_protection = local.current_env.rds_deletion_protection
  skip_final_snapshot = var.environment == "staging"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-mysql"
  })
}