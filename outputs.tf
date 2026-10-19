output "vpc_id" {
  description = "VPC identifier."
  value       = module.network.vpc_id
}

output "app_subnet_ids" {
  description = "Private application subnet IDs."
  value       = module.network.app_subnet_ids
}

output "rds_primary_endpoint" {
  description = "Direct primary endpoint; restrict to approved clients."
  value       = module.database.primary_endpoint
}

output "rds_proxy_endpoint" {
  description = "Proxy endpoint for application read/write traffic."
  value       = module.rds_proxy.endpoint
}

output "rds_read_replica_endpoints" {
  description = "Endpoints for read-only workloads."
  value       = module.database.read_replica_endpoints
}

output "db_secret_arn" {
  description = "ARN of the database credentials secret."
  value       = module.database.secret_arn
}

output "db_kms_key_arn" {
  description = "ARN of the customer-managed database KMS key."
  value       = module.database.kms_key_arn
}
