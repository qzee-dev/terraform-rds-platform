
variable "aws_region" {
  description = "AWS deployment region."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition = contains(
      ["dev", "staging", "prod"],
      var.environment
    )
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "owner" {
  description = "Accountable team or service owner."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "projectname" {
  description = "Project identifier."
  type        = string

  validation {
    condition     = length(trimspace(var.projectname)) > 0
    error_message = "projectname must not be empty."
  }
}

variable "costcenter" {
  description = "Approved finance cost-center identifier."
  type        = string

  validation {
    condition     = length(trimspace(var.costcenter)) > 0
    error_message = "costcenter must not be empty."
  }
}

variable "application_name" {
  description = "Application name."
  type        = string
  default     = "application"
}

variable "repository" {
  description = "Infrastructure repository identifier."
  type        = string
  default     = "terraform-rds-platform"
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Two or more distinct AZ names."
  type        = list(string)

  validation {
    condition = (
      length(var.availability_zones) >= 2 &&
      length(distinct(var.availability_zones)) ==
      length(var.availability_zones)
    )
    error_message = "Specify at least two distinct availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per AZ."
  type        = list(string)

  validation {
    condition = (
      length(var.public_subnet_cidrs) ==
      length(var.availability_zones)
    )
    error_message = "Provide one public subnet CIDR per AZ."
  }
}

variable "private_app_cidrs" {
  description = "Private application subnet CIDRs, one per AZ."
  type        = list(string)

  validation {
    condition = (
      length(var.private_app_cidrs) ==
      length(var.availability_zones)
    )
    error_message = "Provide one application subnet CIDR per AZ."
  }
}

variable "private_db_cidrs" {
  description = "Isolated database subnet CIDRs, one per AZ."
  type        = list(string)

  validation {
    condition = (
      length(var.private_db_cidrs) ==
      length(var.availability_zones)
    )
    error_message = "Provide one database subnet CIDR per AZ."
  }
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway to reduce cost."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "appdb"

  validation {
    condition = can(regex(
      "^[A-Za-z][A-Za-z0-9_]{0,62}$",
      var.db_name
    ))
    error_message = "Invalid database name."
  }
}

variable "db_username" {
  description = "RDS master username."
  type        = string
  default     = "dbadmin"

  validation {
    condition = (
      can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.db_username)) &&
      !contains(["postgres", "rdsadmin"], lower(var.db_username))
    )
    error_message = "Specify a valid, non-reserved master username."
  }
}

variable "db_engine_version" {
  description = "PostgreSQL engine version supported in the region."
  type        = string
  default     = "16.6"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 100

  validation {
    condition     = var.db_allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GiB."
  }
}

variable "db_max_allocated_storage" {
  description = "Maximum storage autoscaling size in GiB."
  type        = number
  default     = 500
}

variable "db_backup_retention_days" {
  description = "Automated backup retention in days."
  type        = number
  default     = 14

  validation {
    condition = (
      var.db_backup_retention_days >= 1 &&
      var.db_backup_retention_days <= 35
    )
    error_message = "Backup retention must be between 1 and 35 days."
  }
}

variable "read_replica_count" {
  description = "Number of read replicas."
  type        = number
  default     = 2

  validation {
    condition = (
      var.read_replica_count >= 0 &&
      var.read_replica_count <= 5 &&
      floor(var.read_replica_count) == var.read_replica_count
    )
    error_message = "Replica count must be an integer from 0 to 5."
  }
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the primary."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when deleting the primary."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply supported database changes immediately."
  type        = bool
  default     = false
}

variable "backup_window" {
  description = "Preferred UTC backup window."
  type        = string
  default     = "01:00-02:00"
}

variable "maintenance_window" {
  description = "Preferred UTC maintenance window."
  type        = string
  default     = "sun:03:00-sun:04:00"
}
