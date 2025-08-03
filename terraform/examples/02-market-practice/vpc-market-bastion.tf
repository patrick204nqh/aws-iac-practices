# Market Bastion VPC
resource "aws_vpc" "market_bastion" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "market-bastion"
  }
}

# Internet Gateway for Bastion
resource "aws_internet_gateway" "market_bastion" {
  vpc_id = aws_vpc.market_bastion.id

  tags = {
    Name = "market-bastion-igw"
  }
}

# Public Subnet for Bastion
resource "aws_subnet" "market_bastion_public" {
  vpc_id                  = aws_vpc.market_bastion.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "market-bastion-public"
    Type = "public"
  }
}

# Route Table for Bastion
resource "aws_route_table" "market_bastion_public" {
  vpc_id = aws_vpc.market_bastion.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.market_bastion.id
  }

  tags = {
    Name = "market-bastion-public-rt"
  }
}

resource "aws_route_table_association" "market_bastion_public" {
  subnet_id      = aws_subnet.market_bastion_public.id
  route_table_id = aws_route_table.market_bastion_public.id
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "bastion_to_prod" {
  count = var.enable_vpc_peering ? 1 : 0

  peer_vpc_id = aws_vpc.market_prod.id
  vpc_id      = aws_vpc.market_bastion.id
  auto_accept = true

  tags = {
    Name = "bastion-to-prod-peering"
  }
}

# Routes for VPC Peering - Bastion to Prod
resource "aws_route" "bastion_to_prod" {
  count = var.enable_vpc_peering ? 1 : 0

  route_table_id            = aws_route_table.market_bastion_public.id
  destination_cidr_block    = aws_vpc.market_prod.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_prod[0].id
}

# Routes for VPC Peering - Prod to Bastion
resource "aws_route" "prod_public_to_bastion" {
  count = var.enable_vpc_peering ? 1 : 0

  route_table_id            = aws_route_table.market_prod_public.id
  destination_cidr_block    = aws_vpc.market_bastion.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_prod[0].id
}

resource "aws_route" "prod_private_to_bastion" {
  count = var.enable_vpc_peering ? 1 : 0

  route_table_id            = aws_route_table.market_prod_private.id
  destination_cidr_block    = aws_vpc.market_bastion.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_prod[0].id
}