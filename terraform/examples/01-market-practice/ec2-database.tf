resource "aws_instance" "database" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.database_instance_type
  subnet_id     = aws_subnet.market_prod_private.id
  
  vpc_security_group_ids = [aws_security_group.database.id]
  
  key_name = var.key_pair_name

  user_data = file("${path.module}/user-data/database.sh")

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "market-database"
    Type = "database"
  }
}