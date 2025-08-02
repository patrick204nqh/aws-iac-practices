# Market Prod VPC
resource "aws_vpc" "market_prod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "market-prod"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "market_prod" {
  vpc_id = aws_vpc.market_prod.id

  tags = {
    Name = "market-prod-igw"
  }
}

# Public Subnet
resource "aws_subnet" "market_prod_public" {
  vpc_id                  = aws_vpc.market_prod.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "market-prod-public"
    Type = "public"
  }
}

# Private Subnet
resource "aws_subnet" "market_prod_private" {
  vpc_id            = aws_vpc.market_prod.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "market-prod-private"
    Type = "private"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "market_prod_public" {
  vpc_id = aws_vpc.market_prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.market_prod.id
  }

  tags = {
    Name = "market-prod-public-rt"
  }
}

resource "aws_route_table_association" "market_prod_public" {
  subnet_id      = aws_subnet.market_prod_public.id
  route_table_id = aws_route_table.market_prod_public.id
}

# NAT Gateway for Private Subnet
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "market-prod-nat-eip"
  }
}

resource "aws_nat_gateway" "market_prod" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.market_prod_public.id

  tags = {
    Name = "market-prod-nat"
  }

  depends_on = [aws_internet_gateway.market_prod]
}

# Route Table for Private Subnet
resource "aws_route_table" "market_prod_private" {
  vpc_id = aws_vpc.market_prod.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.market_prod.id
  }

  tags = {
    Name = "market-prod-private-rt"
  }
}

resource "aws_route_table_association" "market_prod_private" {
  subnet_id      = aws_subnet.market_prod_private.id
  route_table_id = aws_route_table.market_prod_private.id
}