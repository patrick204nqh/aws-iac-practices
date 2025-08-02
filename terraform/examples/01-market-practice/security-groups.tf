# Security Group for Web App
resource "aws_security_group" "webapp" {
  name        = "market-webapp-sg"
  description = "Security group for web application server"
  vpc_id      = aws_vpc.market_prod.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Glances monitoring"
    from_port   = 61208
    to_port     = 61208
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.enable_vpc_peering ? [aws_vpc.market_bastion.cidr_block] : [var.my_ip]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "market-webapp-sg"
  }
}

# Security Group for Database
resource "aws_security_group" "database" {
  name        = "market-database-sg"
  description = "Security group for database server"
  vpc_id      = aws_vpc.market_prod.id

  ingress {
    description     = "MySQL from webapp"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webapp.id]
  }

  ingress {
    description     = "Redis from webapp"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.webapp.id]
  }

  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.enable_vpc_peering ? [aws_vpc.market_bastion.cidr_block] : [var.my_ip]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "market-database-sg"
  }
}

# Security Group for Bastion
resource "aws_security_group" "bastion" {
  name        = "market-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.market_bastion.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "market-bastion-sg"
  }
}