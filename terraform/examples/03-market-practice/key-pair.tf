# Generate RSA private key
resource "tls_private_key" "market_practice" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "market_practice" {
  key_name   = "market-practice-${random_id.suffix.hex}"
  public_key = tls_private_key.market_practice.public_key_openssh

  tags = {
    Name = "market-practice-key-pair"
  }
}

# Generate random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Save private key to local file
resource "local_file" "private_key" {
  content  = tls_private_key.market_practice.private_key_pem
  filename = "${path.module}/market-practice-key.pem"
  
  provisioner "local-exec" {
    command = "chmod 600 ${self.filename}"
  }
}