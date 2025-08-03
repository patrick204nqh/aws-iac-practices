# Generate services configuration for webapp
locals {
  services_config = {
    services = [
      {
        name = "mysql"
        host = aws_instance.database.private_ip
        port = 3306
        type = "tcp"
      },
      {
        name = "redis"
        host = aws_instance.database.private_ip
        port = 6379
        type = "tcp"
      },
      {
        name = "database-ssh"
        host = aws_instance.database.private_ip
        port = 22
        type = "tcp"
      }
    ]
  }
}

resource "aws_instance" "webapp" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.webapp_instance_type
  subnet_id     = aws_subnet.market_prod_public.id
  
  vpc_security_group_ids = [aws_security_group.webapp.id]
  
  key_name = aws_key_pair.market_practice.key_name

  user_data = templatefile("${path.module}/user-data/webapp.sh", {
    services_json = jsonencode(local.services_config)
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "market-webapp"
    Type = "webapp"
  }

  depends_on = [aws_instance.database]
}