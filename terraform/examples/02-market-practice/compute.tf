# Generate services configuration for webapp
locals {
  services_config = {
    services = [
      {
        name = "mysql"
        host = module.database.private_ip
        port = 3306
        type = "tcp"
      },
      {
        name = "redis"
        host = module.database.private_ip
        port = 6379
        type = "tcp"
      },
      {
        name = "database-ssh"
        host = module.database.private_ip
        port = 22
        type = "tcp"
      }
    ]
  }
}

# Web Application Instance
module "webapp" {
  source = "./modules/compute"

  ami_id                 = data.aws_ami.ubuntu.id
  instance_type          = local.current_env.instance_sizes.webapp
  subnet_id              = module.app_vpc.public_subnet_id
  vpc_security_group_ids = [module.app_security.webapp_security_group_id]
  key_name              = aws_key_pair.market_practice.key_name
  
  user_data = templatefile("${path.module}/user-data/webapp.sh", {
    services_json = jsonencode(local.services_config)
  })

  # Cost-optimized storage for webapp (just needs space for Docker images)
  root_volume_size = 10  # 10GB for Docker images and basic OS
  root_volume_type = "gp3" # gp3 is more cost-effective

  instance_name = "${local.name_prefix}-webapp"
  instance_role = "webapp"
  
  tags = local.common_tags
}

# Database Instance
module "database" {
  source = "./modules/compute"

  ami_id                 = data.aws_ami.ubuntu.id
  instance_type          = local.current_env.instance_sizes.database
  subnet_id              = module.app_vpc.private_subnet_id
  vpc_security_group_ids = [module.app_security.database_security_group_id]
  key_name              = aws_key_pair.market_practice.key_name
  
  user_data = file("${path.module}/user-data/database.sh")

  # Cost-optimized storage for database (Docker containers for MySQL + Redis)
  root_volume_size = 12  # 12GB for MySQL/Redis Docker images + some data
  root_volume_type = "gp3" # gp3 is more cost-effective

  instance_name = "${local.name_prefix}-database"
  instance_role = "database"
  
  tags = local.common_tags
}

# Bastion Instance (only for staging environment)
module "bastion" {
  count  = local.current_env.enable_bastion ? 1 : 0
  source = "./modules/compute"

  ami_id                 = data.aws_ami.ubuntu.id
  instance_type          = local.current_env.instance_sizes.bastion
  subnet_id              = module.bastion_vpc[0].public_subnet_id
  vpc_security_group_ids = [module.bastion_security[0].bastion_security_group_id]
  key_name              = aws_key_pair.market_practice.key_name
  
  user_data = file("${path.module}/user-data/bastion.sh")

  # Cost-optimized storage for bastion (smaller volume since it's just a jump box)
  root_volume_size = 8   # 8GB instead of default 20GB
  root_volume_type = "gp3" # gp3 is more cost-effective than gp2

  instance_name = "market-bastion"
  instance_role = "bastion"
  
  tags = local.common_tags
}