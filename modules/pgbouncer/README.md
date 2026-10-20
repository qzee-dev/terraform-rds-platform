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


Example for using the RDS Proxy instead If you want AWS-native RDS Proxy instead of PgBouncer:
HCL
database_proxy_mode = "rds-proxy"
Disable proxy entirely
HCL
database_proxy_mode = "none"
Important production notes

The aws_launch_template currently uses an Amazon Linux 2-compatible base AMI. Replace image_id with a valid AMI ID for your region before applying.
auth_type = md5 is acceptable as a bootstrap pattern, but for stricter enterprise controls you should move to SCRAM or a dedicated auth_user/secret model.
Keep the DB itself private, with no public access.
For real production, use a dedicated WHITELISTED app service account and rotate credentials via Secrets Manager.
Ensure your application connection string points to the PgBouncer endpoint, not the direct RDS endpoint.
If you want, I can next give you:

a full EKS PgBouncer version in the same production-standard style
a full postgresql + pgbouncer connection-string guide for app services
a full Terraform module for both EC2 and EKS selection inside the same repo
