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

output "private_key_path" {
  description = "Path to the generated private key file"
  value       = local_file.private_key.filename
}

output "key_pair_name" {
  description = "Name of the generated key pair"
  value       = aws_key_pair.market_practice.key_name
}

output "ssh_commands" {
  description = "SSH commands using generated key"
  value = {
    bastion = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.bastion.public_ip}"
    webapp_via_bastion = "ssh -i ${local_file.private_key.filename} -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.webapp.private_ip}"
    database_via_bastion = "ssh -i ${local_file.private_key.filename} -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.database.private_ip}"
  }
}

output "vpc_peering_status" {
  description = "VPC peering connection status"
  value       = var.enable_vpc_peering ? "Enabled" : "Disabled"
}

