variable "name_prefix" {
  description = "Resource naming prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the PgBouncer security groups and load balancer."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where PgBouncer EC2 instances run."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Application security group that reaches PgBouncer."
  type        = string
}

variable "db_security_group_id" {
  description = "Database security group that allows PgBouncer access."
  type        = string
}

variable "db_host" {
  description = "Database hostname or endpoint."
  type        = string
}

variable "db_port" {
  description = "Database port."
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name."
  type        = string
}

variable "db_username" {
  description = "Database user name used by PgBouncer."
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the database secret in Secrets Manager."
  type        = string
}

variable "db_secret_kms_key_arn" {
  description = "KMS key ARN used to decrypt the database secret."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for PgBouncer."
  type        = string
  default     = "t3.small"
}

variable "min_size" {
  description = "Minimum ASG size."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired ASG size."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum ASG size."
  type        = number
  default     = 4
}

variable "pgbouncer_port" {
  description = "PgBouncer TCP port."
  type        = number
  default     = 6432
}

variable "pool_mode" {
  description = "PgBouncer pool mode."
  type        = string
  default     = "transaction"
}

variable "default_pool_size" {
  description = "PgBouncer default pool size."
  type        = number
  default     = 50
}

variable "max_client_conn" {
  description = "Maximum client connections accepted by PgBouncer."
  type        = number
  default     = 5000
}

variable "max_db_connections" {
  description = "Maximum DB connections per PgBouncer node."
  type        = number
  default     = 200
}

variable "server_idle_timeout" {
  description = "PgBouncer server idle timeout in seconds."
  type        = number
  default     = 60
}

variable "query_wait_timeout" {
  description = "PgBouncer query wait timeout in seconds."
  type        = number
  default     = 120
}

variable "health_check_interval" {
  description = "Health check interval for the PgBouncer target group."
  type        = number
  default     = 30
}

variable "health_check_threshold" {
  description = "Healthy threshold count for the PgBouncer target group."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}
