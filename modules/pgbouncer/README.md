# PgBouncer module

This module deploys PgBouncer in EC2 behind a private internal Network Load Balancer for production workloads.

## Production standards included
- Private-only network topology
- Multi-AZ deployment through ASG + NLB
- Secrets Manager integration for DB credentials
- IAM least-privilege access
- CloudWatch log group
- Health checks and target groups
- Security group segmentation
- Auto-scaling and instance metadata hardening
- TLS should be enforced between app and PgBouncer and between PgBouncer and PostgreSQL where supported
- PgBouncer pool sizing should be tuned based on real DB connection behavior
