variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
}


variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}