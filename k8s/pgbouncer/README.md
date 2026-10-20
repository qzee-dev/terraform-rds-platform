# PgBouncer on EKS

This directory contains a production-ready PostgreSQL connection pooling setup for EKS using PgBouncer.

## Architecture
- Application pods connect to PgBouncer in the same cluster
- PgBouncer connects to the RDS PostgreSQL primary
- Credentials are loaded securely from AWS Secrets Manager using IRSA
- Network and pod security are hardened
- Horizontal scaling and pod disruption protection are enabled

## Recommended deployment pattern
- Namespace: platform
- Service: ClusterIP
- Private network only
- PgBouncer runs with read-only root filesystem and non-root user
- Data path: app -> PgBouncer -> RDS

## Important notes
- Use transaction pooling only if the app tolerates pooled transactions
- Do not use PgBouncer for legacy session-bound PostgreSQL logic
- Keep DB credentials in Secrets Manager, not in app config
- Use a dedicated database user for the pooler



Quick rule
If the app behaves like a stateless web or API service, PgBouncer is usually a great fit.

If the app behaves like a sessionful legacy database client, PgBouncer needs careful design and may not be appropriate.

Final recommendation
PgBouncer is a strong fit for:

fintech apps
banking APIs
payment platforms
SaaS backends
mobile apps
e-commerce services
high-concurrency CRUD workloads
It is a poor fit for:

long-running transaction applications
session-dependent PostgreSQL workloads
temp-table-heavy ETL jobs
custom PostgreSQL logic that depends on stable connection state
Use PgBouncer when your app is built for connection pooling, not session affinity.

This README-style summary is ready to paste into a README.md file in your project folder or repo.


