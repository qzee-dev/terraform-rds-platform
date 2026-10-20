
module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.private_app_cidrs
  db_subnet_cidrs     = var.private_db_cidrs
  single_nat_gateway  = var.single_nat_gateway

  tags = local.common_tags
}

module "database" {
  source = "./modules/database"

  name_prefix           = local.name_prefix
  db_name               = var.db_name
  db_username           = var.db_username
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  backup_retention_days = var.db_backup_retention_days
  backup_window         = var.backup_window
  maintenance_window    = var.maintenance_window

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  apply_immediately   = var.apply_immediately
  read_replica_count  = var.read_replica_count

  db_subnet_ids       = module.network.db_subnet_ids
  db_security_group_id = module.network.db_security_group_id

  tags = local.common_tags
}

module "rds_proxy" {
  source = "./modules/rds-proxy"
  count  = var.database_proxy_mode == "rds-proxy" ? 1 : 0

  name_prefix    = local.name_prefix
  db_instance_id = module.database.primary_id
  db_secret_arn  = module.database.secret_arn

  db_secret_kms_key_arn = module.database.kms_key_arn

  subnet_ids = module.network.app_subnet_ids

  security_group_ids = [
    module.network.proxy_security_group_id
  ]

  require_tls                       = var.proxy_require_tls
  iam_auth                          = var.proxy_iam_auth
  idle_client_timeout               = var.proxy_idle_client_timeout
  connection_borrow_timeout         = var.proxy_connection_borrow_timeout
  max_connections_percent           = var.proxy_max_connections_percent
  max_idle_connections_percent      = var.proxy_max_idle_connections_percent
  debug_logging                     = var.proxy_debug_logging

  borrow_latency_alarm_enabled      = var.proxy_borrow_latency_alarm_enabled
  borrow_latency_threshold_ms       = var.proxy_borrow_latency_threshold_ms
  borrow_latency_period             = var.proxy_borrow_latency_period
  borrow_latency_evaluations        = var.proxy_borrow_latency_evaluations

  tags = local.common_tags
}

module "pgbouncer" {
  source = "./modules/pgbouncer"
  count  = var.database_proxy_mode == "pgbouncer" ? 1 : 0

  name_prefix = local.name_prefix

  vpc_id = module.network.vpc_id
  subnet_ids = module.network.app_subnet_ids

  app_security_group_id = module.network.app_security_group_id
  db_security_group_id = module.network.db_security_group_id

  db_host = module.database.primary_endpoint
  db_port = 5432
  db_name = var.db_name
  db_username = var.db_username

  db_secret_arn = module.database.secret_arn
  db_secret_kms_key_arn = module.database.kms_key_arn

  instance_type = var.pgbouncer_instance_type
  min_size      = var.pgbouncer_min_size
  desired_capacity = var.pgbouncer_desired_capacity
  max_size      = var.pgbouncer_max_size

  pgbouncer_port = var.pgbouncer_port
  pool_mode = var.pgbouncer_pool_mode
  default_pool_size = var.pgbouncer_default_pool_size
  max_client_conn = var.pgbouncer_max_client_conn
  max_db_connections = var.pgbouncer_max_db_connections
  server_idle_timeout = var.pgbouncer_server_idle_timeout
  query_wait_timeout = var.pgbouncer_query_wait_timeout
  health_check_interval = var.pgbouncer_health_check_interval
  health_check_threshold = var.pgbouncer_health_check_threshold

  tags = local.common_tags
}





