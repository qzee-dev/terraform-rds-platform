locals {
  pgbouncer_name = "${var.name_prefix}-pgbouncer"
  pgbouncer_port = var.pgbouncer_port
  pgbouncer_config = <<-EOT
[databases]
${var.db_name} = host=${var.db_host} port=${var.db_port} dbname=${var.db_name} user=${var.db_username}

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = ${var.pgbouncer_port}
unix_socket_dir = /tmp
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename=$1
pool_mode = ${var.pool_mode}
max_client_conn = ${var.max_client_conn}
default_pool_size = ${var.default_pool_size}
max_db_connections = ${var.max_db_connections}
server_idle_timeout = ${var.server_idle_timeout}
query_wait_timeout = ${var.query_wait_timeout}
ignore_startup_parameters = extra_float_digits
reserve_pool_size = 10
reserve_pool_timeout = 5
logfile = /var/log/pgbouncer.log
pidfile = /var/run/pgbouncer.pid
admin_users = postgres
stats_users = postgres
EOT
}

resource "aws_security_group" "pgbouncer" {
  name        = "${var.name_prefix}-pgbouncer-sg"
  description = "PgBouncer access from application workloads and database path"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-pgbouncer-sg"
    Role = "database-proxy"
  })
}

resource "aws_vpc_security_group_ingress_rule" "pgbouncer_from_app" {
  security_group_id = aws_security_group.pgbouncer.id

  referenced_security_group_id = var.app_security_group_id

  description = "PgBouncer connections from application workloads"
  ip_protocol = "tcp"
  from_port   = var.pgbouncer_port
  to_port     = var.pgbouncer_port
}

resource "aws_vpc_security_group_egress_rule" "pgbouncer_to_db" {
  security_group_id = aws_security_group.pgbouncer.id

  referenced_security_group_id = var.db_security_group_id

  description = "PgBouncer to RDS PostgreSQL"
  ip_protocol = "tcp"
  from_port   = var.db_port
  to_port     = var.db_port
}

resource "aws_vpc_security_group_egress_rule" "pgbouncer_https_outbound" {
  security_group_id = aws_security_group.pgbouncer.id

  description = "Outbound HTTPS for AWS API access and package updates"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "pgbouncer_all_egress" {
  security_group_id = aws_security_group.pgbouncer.id

  description = "All other outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_iam_role" "pgbouncer" {
  name = "${var.name_prefix}-pgbouncer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-pgbouncer-role"
  })
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.name_prefix}-pgbouncer-secrets"
  role = aws_iam_role.pgbouncer.id

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

resource "aws_iam_instance_profile" "pgbouncer" {
  name = "${var.name_prefix}-pgbouncer-profile"
  role = aws_iam_role.pgbouncer.name
}

resource "aws_cloudwatch_log_group" "pgbouncer" {
  name              = "/aws/ec2/pgbouncer/${var.name_prefix}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-pgbouncer-logs"
  })
}

resource "aws_launch_template" "pgbouncer" {
  name_prefix   = "${var.name_prefix}-pgbouncer-"
  image_id      = "ami-0c5b7d3b2a9d6e6c4" # replace with your region-appropriate AMI ID
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.pgbouncer.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.pgbouncer.arn
  }

  user_data = base64encode(<<-EOT
#!/bin/bash
set -euxo pipefail

yum update -y
yum install -y amazon-linux-extras
amazon-linux-extras enable postgresql14
yum install -y postgresql14 pgbouncer jq

mkdir -p /etc/pgbouncer
mkdir -p /var/log

cat <<'EOF_PG' >/etc/pgbouncer/pgbouncer.ini
${local.pgbouncer_config}
EOF_PG

aws secretsmanager get-secret-value \
  --secret-id "${var.db_secret_arn}" \
  --query SecretString \
  --output text > /tmp/db_secret.json

python3 - <<'PY'
import json, hashlib
import os

with open("/tmp/db_secret.json", "r", encoding="utf-8") as fh:
    secret = json.load(fh)

username = secret.get("username")
password = secret.get("password")

if not username or not password:
    raise SystemExit("DB credentials missing from secret")

md5_hash = hashlib.md5((password + username).encode("utf-8")).hexdigest()
with open("/etc/pgbouncer/userlist.txt", "w", encoding="utf-8") as fh:
    fh.write(f'"{username}" "{md5_hash}"\n')
PY

chmod 600 /etc/pgbouncer/userlist.txt

systemctl enable pgbouncer
systemctl restart pgbouncer || systemctl start pgbouncer

cat <<'EOF_SYS' >/etc/systemd/system/pgbouncer.service
[Unit]
Description=PgBouncer
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pgbouncer /etc/pgbouncer/pgbouncer.ini
ExecStartPre=/usr/local/bin/pgbouncer -d /etc/pgbouncer/pgbouncer.ini
Restart=on-failure
RestartSec=5
User=pgbouncer
Group=pgbouncer

[Install]
WantedBy=multi-user.target
EOF_SYS

mkdir -p /var/lib/pgbouncer
useradd -m -p '*' pgbouncer || true
chown -R pgbouncer:pgbouncer /etc/pgbouncer /var/log /var/lib/pgbouncer

systemctl daemon-reload
systemctl enable pgbouncer
systemctl restart pgbouncer || systemctl start pgbouncer

/opt/aws/bin/cfn-signal -s --stack-id ${self.stack_id} --region ${var.region} || true
EOT

  )
  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-pgbouncer"
      Role = "database-proxy"
    })
  }

  depends_on = [
    aws_iam_role_policy.secrets_access,
    aws_cloudwatch_log_group.pgbouncer
  ]
}

resource "aws_lb" "pgbouncer" {
  name               = "${var.name_prefix}-pgbouncer-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-pgbouncer-nlb"
    Role = "database-proxy"
  })
}

resource "aws_lb_target_group" "pgbouncer" {
  name     = "${var.name_prefix}-pgbouncer-tg"
  port     = var.pgbouncer_port
  protocol = "TCP"
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = var.pgbouncer_port
    protocol            = "TCP"
    interval            = var.health_check_interval
    healthy_threshold   = var.health_check_threshold
    unhealthy_threshold = 3
    matcher             = null
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-pgbouncer-tg"
    Role = "database-proxy"
  })
}

resource "aws_autoscaling_group" "pgbouncer" {
  name                      = "${var.name_prefix}-pgbouncer-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_grace_period = 180
  health_check_type         = "EC2"

  launch_template {
    id      = aws_launch_template.pgbouncer.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-pgbouncer"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "database-proxy"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [
    aws_launch_template.pgbouncer,
    aws_lb_target_group.pgbouncer
  ]
}

resource "aws_lb_listener" "pgbouncer" {
  load_balancer_name = aws_lb.pgbouncer.name
  port               = var.pgbouncer_port
  protocol           = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pgbouncer.arn
  }
}
