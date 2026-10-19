
aws_region = "eu-west-1"

environment  = "prod"
owner        = "platform-engineering"
projectname  = "customer-platform"
costcenter   = "CC-1001"

application_name = "customer-api"
repository       = "terraform-rds-platform"

vpc_cidr = "10.20.0.0/16"

availability_zones = [
  "eu-west-1a",
  "eu-west-1b",
  "eu-west-1c"
]

public_subnet_cidrs = [
  "10.20.1.0/24",
  "10.20.2.0/24",
  "10.20.3.0/24"
]

private_app_cidrs = [
  "10.20.11.0/24",
  "10.20.12.0/24",
  "10.20.13.0/24"
]

private_db_cidrs = [
  "10.20.21.0/24",
  "10.20.22.0/24",
  "10.20.23.0/24"
]

single_nat_gateway = false

db_name           = "appdb"
db_username       = "dbadmin"
db_engine_version = "16.6"
db_instance_class = "db.t4g.medium"

db_allocated_storage     = 100
db_max_allocated_storage = 500

db_backup_retention_days = 14
read_replica_count       = 2

deletion_protection = true
skip_final_snapshot = false
apply_immediately   = false

backup_window      = "01:00-02:00"
maintenance_window = "sun:03:00-sun:04:00"





# ============================================================
# RDS PROXY — PRODUCTION CONFIGURATION
# ============================================================

# Proxy naming
proxy_enabled = true

# Authentication
proxy_require_tls = true
proxy_iam_auth    = "DISABLED"

# Connection management
proxy_idle_client_timeout          = 1800
proxy_connection_borrow_timeout    = 120
proxy_max_connections_percent      = 80
proxy_max_idle_connections_percent = 40

# Logging
proxy_debug_logging = false

# CloudWatch connection-borrow-latency alarm
proxy_borrow_latency_alarm_enabled = true
proxy_borrow_latency_threshold_ms  = 1000
proxy_borrow_latency_period        = 300
proxy_borrow_latency_evaluations   = 3



