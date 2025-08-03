packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS region to build AMI in"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for building AMI"
}

variable "ami_name_prefix" {
  type        = string
  default     = "market-database"
  description = "Prefix for AMI name"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "database" {
  ami_name      = "${var.ami_name_prefix}-${local.timestamp}"
  instance_type = var.instance_type
  region        = var.aws_region
  
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  
  ssh_username = "ubuntu"
  
  # Optimize EBS for cost
  ebs_optimized = true
  
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 15  # Slightly larger to accommodate Docker images
    volume_type = "gp3"
    delete_on_termination = true
  }
  
  tags = {
    Name        = "market-database-ami-${local.timestamp}"
    Project     = "market-practice"
    Environment = "base"
    ManagedBy   = "packer"
    Purpose     = "database-with-docker-images"
  }
}

build {
  name = "database-ami"
  sources = [
    "source.amazon-ebs.database"
  ]

  # Update system and install Docker
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      
      # Install Docker
      "sudo mkdir -m 0755 -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      
      # Start Docker service
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ubuntu",
      
      # Install Docker Compose standalone
      "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose"
    ]
  }

  # Pre-pull Docker images
  provisioner "shell" {
    inline = [
      "# Wait for Docker to be ready",
      "sleep 10",
      
      "# Pre-pull MySQL image",
      "sudo docker pull mysql:8.0",
      
      "# Pre-pull Redis image", 
      "sudo docker pull redis:7-alpine",
      
      "# Verify images are pulled",
      "sudo docker images",
      
      "# Clean up Docker system to reduce AMI size",
      "sudo docker system prune -f"
    ]
  }

  # Create the docker-compose file
  provisioner "file" {
    content = <<EOF
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: market_mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: marketroot123
      MYSQL_DATABASE: market
      MYSQL_USER: market_user
      MYSQL_PASSWORD: market_pass123
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  redis:
    image: redis:7-alpine
    container_name: market_redis
    restart: always
    command: redis-server --requirepass market_redis123
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  mysql_data:
  redis_data:
EOF
    destination = "/tmp/docker-compose.yml"
  }

  # Setup startup script
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/docker-compose.yml /home/ubuntu/docker-compose.yml",
      "sudo chown ubuntu:ubuntu /home/ubuntu/docker-compose.yml",
      
      "# Create startup script for database services",
      "cat << 'EOF' | sudo tee /usr/local/bin/start-database-services.sh",
      "#!/bin/bash",
      "cd /home/ubuntu",
      "docker-compose up -d",
      "sleep 30",
      "docker ps > /var/log/database-status.log",
      "docker-compose logs > /var/log/database-logs.log",
      "EOF",
      
      "sudo chmod +x /usr/local/bin/start-database-services.sh",
      
      "# Create systemd service for auto-start",
      "cat << 'EOF' | sudo tee /etc/systemd/system/database-services.service",
      "[Unit]",
      "Description=Market Database Services",
      "Requires=docker.service",
      "After=docker.service",
      "",
      "[Service]",
      "Type=oneshot",
      "RemainAfterExit=yes",
      "ExecStart=/usr/local/bin/start-database-services.sh",
      "User=ubuntu",
      "Group=ubuntu",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      
      "sudo systemctl enable database-services.service"
    ]
  }

  # Final cleanup
  provisioner "shell" {
    inline = [
      "# Clean package cache",
      "sudo apt-get clean",
      
      "# Clear logs",
      "sudo rm -rf /var/log/*.log /var/log/*/*.log",
      
      "# Clear bash history",
      "history -c && history -w",
      
      "# Clear cloud-init logs to reduce AMI size",
      "sudo cloud-init clean --logs"
    ]
  }
}