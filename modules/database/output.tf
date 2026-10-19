output "primary_id" {
  description = "Primary RDS instance identifier."
  value       = aws_db_instance.primary.identifier
}

output "primary_endpoint" {
  description = "Primary PostgreSQL endpoint."
  value       = aws_db_instance.primary.address
}

output "secret_arn" {
  description = "Secrets Manager ARN for master credentials."
  value       = aws_secretsmanager_secret.master.arn
}

output "kms_key_arn" {
  description = "Customer-managed KMS key ARN."
  value       = aws_kms_key.database.arn
}

output "read_replica_endpoints" {
  description = "Read replica endpoints."
  value       = aws_db_instance.read_replica[*].address
}

output "db_subnet_group_name" {
  description = "RDS subnet group name."
  value       = aws_db_subnet_group.this.name
}
