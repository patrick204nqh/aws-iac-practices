variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (staging, prod)"
  type        = string
  default     = "staging"
  
  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Environment must be either 'staging' or 'prod'."
  }
}

variable "my_ip" {
  description = "Your IP address for SSH access (use format: x.x.x.x/32)"
  type        = string
}

variable "enable_vpc_peering" {
  description = "Enable VPC peering between application and bastion VPCs"
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Password for the RDS MySQL database"
  type        = string
  sensitive   = true
}