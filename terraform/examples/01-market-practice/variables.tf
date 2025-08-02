variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "key_pair_name" {
  description = "Name of existing EC2 key pair for SSH access"
  type        = string
}

variable "my_ip" {
  description = "Your IP address for SSH access (use format: x.x.x.x/32)"
  type        = string
}

variable "webapp_instance_type" {
  description = "Instance type for webapp server"
  type        = string
  default     = "t3.micro"
}

variable "database_instance_type" {
  description = "Instance type for database server"
  type        = string
  default     = "t3.micro"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion server"
  type        = string
  default     = "t3.micro"
}

variable "enable_vpc_peering" {
  description = "Enable VPC peering between market-prod and market-bastion"
  type        = bool
  default     = true
}