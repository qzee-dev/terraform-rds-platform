resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "app" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = var.app_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-${count.index + 1}"
    Tier = "private-app"
  })
}

resource "aws_subnet" "db" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = var.db_subnet_cidrs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-${count.index + 1}"
    Tier = "isolated-db"
  })
}

# Public routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT gateways
locals {
  nat_gateway_count = (
    var.single_nat_gateway
    ? 1
    : length(var.availability_zones)
  )
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

# Private application routing
resource "aws_route_table" "app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-rt-${count.index + 1}"
  })
}

resource "aws_route" "app_nat" {
  count = length(var.availability_zones)

  route_table_id = aws_route_table.app[count.index].id

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.this[
    var.single_nat_gateway ? 0 : count.index
  ].id
}

resource "aws_route_table_association" "app" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

# Isolated database routing: no internet route
resource "aws_route_table" "db" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "db" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[count.index].id
}

# Application security group
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Application workloads"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
  })
}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS Proxy security group
resource "aws_security_group" "proxy" {
  name        = "${var.name_prefix}-proxy-sg"
  description = "RDS Proxy access from application workloads"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-proxy-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "proxy_from_app" {
  security_group_id = aws_security_group.proxy.id

  referenced_security_group_id = aws_security_group.app.id

  description = "PostgreSQL connections from application workloads"
  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
}

resource "aws_vpc_security_group_egress_rule" "proxy_to_db" {
  security_group_id = aws_security_group.proxy.id

  referenced_security_group_id = aws_security_group.db.id

  description = "PostgreSQL connections to RDS"
  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
}

# Database security group
resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "Database access from approved security groups"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "db_from_proxy" {
  security_group_id = aws_security_group.db.id

  referenced_security_group_id = aws_security_group.proxy.id

  description = "PostgreSQL connections from RDS Proxy"
  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id = aws_security_group.db.id

  referenced_security_group_id = aws_security_group.app.id

  description = "Approved direct database and replica access"
  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
}

resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.db.id
  description       = "Database outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
