Network security notes

Application workloads can reach the proxy on TCP port 5432.

The proxy can reach PostgreSQL on TCP port 5432.

Direct database connections from the application security group are permitted for approved administrative or replica-read workloads. Remove this ingress rule if all application access must go through the proxy.

The application security group's HTTPS-only egress rule may need additional, narrowly scoped rules or VPC endpoints for services your workloads use.

A single NAT gateway reduces cost but introduces a shared egress dependency and potential cross-AZ charges. The default creates one NAT gateway per AZ.
