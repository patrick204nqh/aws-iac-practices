provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Custom AMI removed - no longer needed since we use RDS and ElastiCache

# Application VPC
module "app_vpc" {
  source = "./modules/vpc"

  vpc_name             = local.name_prefix
  vpc_cidr             = local.current_env.vpc_cidr
  public_subnet_cidr   = local.current_env.public_subnet
  private_subnet_cidr  = local.current_env.private_subnet
  availability_zone    = data.aws_availability_zones.available.names[0]
  
  tags = local.common_tags
}

# Bastion VPC (only for staging environment)
module "bastion_vpc" {
  count  = local.current_env.enable_bastion ? 1 : 0
  source = "./modules/vpc"

  vpc_name           = "market-bastion"
  vpc_cidr           = local.bastion_vpc_cidr
  public_subnet_cidr = local.bastion_subnet
  availability_zone  = data.aws_availability_zones.available.names[0]
  
  tags = local.common_tags
}

# Security Groups for Application VPC
module "app_security" {
  source = "./modules/security"

  vpc_id             = module.app_vpc.vpc_id
  bastion_vpc_cidr   = local.current_env.enable_bastion ? local.bastion_vpc_cidr : ""
  my_ip              = var.my_ip
  enable_vpc_peering = local.current_env.enable_vpc_peering
  name_prefix        = local.name_prefix
  
  tags = local.common_tags
}

# Security Groups for Bastion VPC
module "bastion_security" {
  count  = local.current_env.enable_bastion ? 1 : 0
  source = "./modules/security"

  vpc_id             = module.bastion_vpc[0].vpc_id
  bastion_vpc_cidr   = local.bastion_vpc_cidr
  my_ip              = var.my_ip
  enable_vpc_peering = local.current_env.enable_vpc_peering
  name_prefix        = "market-mgmt"
  
  tags = local.common_tags
}

# VPC Peering Connection (only for staging)
resource "aws_vpc_peering_connection" "bastion_to_app" {
  count = local.current_env.enable_vpc_peering ? 1 : 0

  peer_vpc_id = module.app_vpc.vpc_id
  vpc_id      = module.bastion_vpc[0].vpc_id
  auto_accept = true

  tags = merge(local.common_tags, {
    Name = "bastion-to-${var.environment}-peering"
  })
}

# VPC Peering Routes (only for staging)
resource "aws_route" "bastion_to_app" {
  count = local.current_env.enable_vpc_peering ? 1 : 0

  route_table_id            = module.bastion_vpc[0].public_route_table_id
  destination_cidr_block    = module.app_vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_app[0].id
}

resource "aws_route" "app_public_to_bastion" {
  count = local.current_env.enable_vpc_peering ? 1 : 0

  route_table_id            = module.app_vpc.public_route_table_id
  destination_cidr_block    = module.bastion_vpc[0].vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_app[0].id
}

resource "aws_route" "app_private_to_bastion" {
  count = local.current_env.enable_vpc_peering ? 1 : 0

  route_table_id            = module.app_vpc.private_route_table_id
  destination_cidr_block    = module.bastion_vpc[0].vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_app[0].id
}