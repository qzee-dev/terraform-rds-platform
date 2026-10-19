
output "endpoint" {
  description = "RDS Proxy endpoint for application read/write traffic."
  value       = aws_db_proxy.this.endpoint
}

output "proxy_name" {
  description = "RDS Proxy name."
  value       = aws_db_proxy.this.name
}
