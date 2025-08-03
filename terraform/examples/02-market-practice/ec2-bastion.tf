resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.market_bastion_public.id
  
  vpc_security_group_ids = [aws_security_group.bastion.id]
  
  key_name = aws_key_pair.market_practice.key_name

  user_data = templatefile("${path.module}/user-data/bastion.sh", {
    webapp_private_ip   = aws_instance.webapp.private_ip
    database_private_ip = aws_instance.database.private_ip
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name = "market-bastion"
    Type = "bastion"
  }

  depends_on = [aws_instance.webapp, aws_instance.database]
}