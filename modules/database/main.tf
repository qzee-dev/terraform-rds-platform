

resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-db-subnets"
  description = "Private isolated subnets for RDS"
  subnet_ids  = var.db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnets"
  })
}

# Customer-managed encryption key
resource "aws_kms_key" "database" {
  description             = "KMS key for ${var.name_prefix} RDS"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-kms"
  })
}

resource "aws_kms_alias" "database" {
  name          = "alias/${var.name_prefix}-rds"
  target_key_id = aws_kms_key.database.key_id
}

# Generate the master password.
# Terraform state must be encrypted and access-controlled.
resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "master" {
  name        = "${var.name_prefix}/rds/master"
  description = "RDS master credentials"

  kms_key_id              = aws_kms_key.database.arn
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-master-secret"
  })
}

resource "aws_secretsmanager_secret_version" "master" {
  secret_id = aws_secretsmanager_secret.master.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master.result
  })
}

# PostgreSQL parameter group
resource "aws_db_parameter_group" "this" {
  name        = "${var.name_prefix}-postgres16"
  family      = "postgres16"
  description = "Baseline PostgreSQL 16 parameters"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres16"
  })
}

# Enhanced Monitoring IAM role
resource "aws_iam_role" "monitoring" {
  name = "${var.name_prefix}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role = aws_iam_role.monitoring.name

  policy_arn = (
    "arn:aws:iam::aws:policy/service-role/" 
    # Replace this expression with the full policy ARN below.
  )
}
Replace the final monitoring attachment above with this complete resource (the ARN is a single literal string):


hcl

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
Continue in the same modules/database/main.tf file with the primary and replica resources:


hcl

resource "aws_db_instance" "primary" {
  identifier = "${var.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username
  password = random_password.master.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false

  storage_type          = "gp3"
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  storage_encrypted = true
  kms_key_id        = aws_kms_key.database.arn

  multi_az = true

  backup_retention_period = var.backup_retention_days
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot

  final_snapshot_identifier = "${var.name_prefix}-final"

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  # Validate Performance Insights support and retention
  # for the selected engine, region, and account.
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.database.arn
  performance_insights_retention_period = 7

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.monitoring.arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-primary"
    Role = "primary"
  })

  depends_on = [
    aws_secretsmanager_secret_version.master,
    aws_iam_role_policy_attachment.monitoring
  ]

  lifecycle {
    precondition {
      condition = (
        var.max_allocated_storage >= var.allocated_storage
      )

      error_message = (
        "Maximum allocated storage must be >= initial storage."
      )
    }
  }
}

resource "aws_db_instance" "read_replica" {
  count = var.read_replica_count

  identifier = (
    "${var.name_prefix}-postgres-read-${count.index + 1}"
  )

  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.instance_class

  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]

  # Replicas inherit storage encryption from the encrypted source.
  # Confirm the supported replica/KMS configuration for your region.
  storage_encrypted = true
  kms_key_id        = aws_kms_key.database.arn

  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.monitoring.arn

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.database.arn
  performance_insights_retention_period = 7

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-read-${count.index + 1}"
    Role = "read-replica"
  })

  depends_on = [
    aws_iam_role_policy_attachment.monitoring
  ]
}
