
variable "name_prefix" {
  type = string
}

variable "db_instance_id" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "db_secret_kms_key_arn" {
  type        = string
  description = "KMS key protecting the database credentials secret."
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}
