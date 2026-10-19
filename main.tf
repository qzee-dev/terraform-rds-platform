
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

  name_prefix    = local.name_prefix
  db_instance_id = module.database.primary_id
  db_secret_arn  = module.database.secret_arn

  db_secret_kms_key_arn = module.database.kms_key_arn

  subnet_ids = module.network.app_subnet_ids

  security_group_ids = [
    module.network.proxy_security_group_id
  ]

  tags = local.common_tags
}main.tf
