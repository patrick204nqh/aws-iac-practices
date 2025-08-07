resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = var.vpc_security_group_ids
  key_name              = var.key_name
  user_data             = var.user_data

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = var.root_volume_encrypted
    
    tags = merge(var.tags, {
      Name = "${var.instance_name}-root-volume"
    })
  }

  tags = merge(var.tags, {
    Name = var.instance_name
    Role = var.instance_role
  })

  lifecycle {
    create_before_destroy = true
  }
}