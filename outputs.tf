output "workspace" {
  description = "Active Terraform workspace"
  value       = terraform.workspace
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.app[*].id
}

output "instance_public_ips" {
  description = "Public IPs of the EC2 instances"
  value       = aws_instance.app[*].public_ip
}

output "instance_type" {
  description = "Instance type in use"
  value       = var.instance_type
}

output "availability_zones_used" {
  description = "AZs available in the region (from data lookup)"
  value       = data.aws_availability_zones.available.names
}
