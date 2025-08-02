output "webapp_public_ip" {
  description = "Public IP of webapp server"
  value       = aws_instance.webapp.public_ip
}

output "webapp_url" {
  description = "URL to access the webapp"
  value       = "http://${aws_instance.webapp.public_ip}"
}

output "glances_url" {
  description = "URL to access Glances monitoring"
  value       = "http://${aws_instance.webapp.public_ip}:61208"
}

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "database_private_ip" {
  description = "Private IP of database server"
  value       = aws_instance.database.private_ip
}

output "ssh_commands" {
  description = "SSH commands"
  value = {
    bastion = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_instance.bastion.public_ip}"
    webapp_via_bastion = "ssh -i ${var.key_pair_name}.pem -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.webapp.private_ip}"
    database_via_bastion = "ssh -i ${var.key_pair_name}.pem -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.database.private_ip}"
  }
}

output "vpc_peering_status" {
  description = "VPC peering connection status"
  value       = var.enable_vpc_peering ? "Enabled" : "Disabled"
}

output "total_estimated_cost" {
  description = "Estimated monthly cost (USD)"
  value       = "~$35-40/month (mainly NAT Gateway: $32)"
}