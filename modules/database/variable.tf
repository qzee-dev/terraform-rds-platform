variable "name_prefix" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  type = number
}

variable "backup_retention_days" {
  type = number
}

variable "backup_window" {
  type = string
}

variable "maintenance_window" {
  type = string
}

variable "deletion_protection" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}

variable "apply_immediately" {
  type = bool
}

variable "read_replica_count" {
  type = number
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
