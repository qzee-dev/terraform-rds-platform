output "vpc_id" {
  description = "VPC identifier."
  value       = aws_vpc.this.id
}

output "app_subnet_ids" {
  description = "Private application subnet IDs."
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "Isolated database subnet IDs."
  value       = aws_subnet.db[*].id
}

output "db_security_group_id" {
  description = "Database security group ID."
  value       = aws_security_group.db.id
}

output "proxy_security_group_id" {
  description = "RDS Proxy security group ID."
  value       = aws_security_group.proxy.id
}

output "app_security_group_id" {
  description = "Application security group ID."
  value       = aws_security_group.app.id
}
