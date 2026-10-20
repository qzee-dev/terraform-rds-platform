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


output "database_proxy_endpoint" {
  description = "Active database proxy endpoint chosen by database_proxy_mode."

  value = (
    var.database_proxy_mode == "rds-proxy" ? module.rds_proxy[0].endpoint :
    var.database_proxy_mode == "pgbouncer" ? module.pgbouncer[0].endpoint :
    null
  )
}

output "rds_proxy_endpoint" {
  description = "Legacy RDS Proxy endpoint when selected."
  value = var.database_proxy_mode == "rds-proxy" ? module.rds_proxy[0].endpoint : null
}

output "pgbouncer_endpoint" {
  description = "PgBouncer endpoint when selected."
  value = var.database_proxy_mode == "pgbouncer" ? module.pgbouncer[0].endpoint : null
}
