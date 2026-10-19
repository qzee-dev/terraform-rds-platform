resource "aws_iam_role" "proxy" {
  name = "${var.name_prefix}-rds-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "rds.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "secrets" {
  name = "${var.name_prefix}-proxy-secrets"
  role = aws_iam_role.proxy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = var.db_secret_arn
      },
      {
        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = var.db_secret_kms_key_arn
      }
    ]
  })
}

resource "aws_db_proxy" "this" {
  name        = "${var.name_prefix}-proxy"
  engine_family = "POSTGRESQL"

  role_arn               = aws_iam_role.proxy.arn
  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = var.security_group_ids

  require_tls          = true
  idle_client_timeout  = 1800
  debug_logging        = false

  auth {
    auth_scheme = "SECRETS"
    description = "Secrets Manager authentication"
    iam_auth    = "DISABLED"
    secret_arn  = var.db_secret_arn
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-proxy"
    Role = "database-proxy"
  })

  depends_on = [
    aws_iam_role_policy.secrets
  ]
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 80
    max_idle_connections_percent = 40
  }
}

resource "aws_db_proxy_target" "primary" {
  db_proxy_name          = aws_db_proxy.this.name
  target_group_name      = aws_db_proxy_default_target_group.this.name
  db_instance_identifier = var.db_instance_id
}

resource "aws_cloudwatch_metric_alarm" "borrow_latency" {
  alarm_name = "${var.name_prefix}-proxy-borrow-latency"

  alarm_description = (
    "RDS Proxy connection borrow latency is elevated."
  )

  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnectionsBorrowLatency"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 1000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBProxyName = aws_db_proxy.this.name
  }

  tags = var.tags
}
