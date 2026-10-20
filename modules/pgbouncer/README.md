# PgBouncer Module

This Terraform module deploys **PgBouncer on Amazon EC2 behind an internal Network Load Balancer (NLB)** to provide connection pooling for production PostgreSQL workloads.

The module is designed for private network connectivity, high availability, secure credential management, and scalable database connection handling.

## Architecture Overview

The module uses the following AWS components:

- **Amazon EC2:** Hosts PgBouncer instances.
- **Auto Scaling Group (ASG):** Maintains the desired number of PgBouncer instances and supports automatic scaling and instance replacement.
- **Internal Network Load Balancer (NLB):** Distributes application connections across healthy PgBouncer instances without exposing the service publicly.
- **AWS Secrets Manager:** Stores database credentials.
- **AWS IAM:** Grants PgBouncer instances only the permissions required to retrieve secrets and perform their assigned tasks.
- **Amazon CloudWatch Logs:** Centralizes PgBouncer logs for monitoring and troubleshooting.
- **Security groups:** Restrict network access between application services, PgBouncer, and PostgreSQL.
- **EC2 launch template:** Defines the instance configuration, AMI, security settings, and bootstrap process.

### Connection Flow

```
Application Services
        |
        v
Internal Network Load Balancer
        |
        v
PgBouncer EC2 Instances
(Managed by Auto Scaling Group)
        |
        v
Amazon RDS for PostgreSQL
```

All components should communicate over private network paths. The database should not require public accessibility.

## Production Standards

The module is designed to support the following production practices:

| Area | Implementation |
| --- | --- |
| Network security | Private-only connectivity for PgBouncer and the database |
| High availability | Multi-AZ deployment using an Auto Scaling Group and internal NLB |
| Credential management | AWS Secrets Manager integration |
| Access control | Least-privilege IAM permissions |
| Logging | CloudWatch log group for operational visibility |
| Health checks | NLB target group health checks |
| Network segmentation | Security groups restricting traffic between tiers |
| Scaling | Auto Scaling Group configuration |
| Instance security | EC2 metadata hardening and secure launch-template settings |
| Encryption | TLS between applications, PgBouncer, and PostgreSQL where supported and configured |
| Connection management | Pool sizing based on measured application and database workloads |

> **Important:** These are the intended production standards. Verify that each control is implemented and enabled in the Terraform configuration before treating the module as production-ready.

## Choosing a Database Connection Proxy

The platform can use PgBouncer, Amazon RDS Proxy, or no proxy, depending on the application's connection-management requirements and the root module's supported configuration.

### Option 1: PgBouncer

Use the EC2-based PgBouncer module when you need PostgreSQL-specific connection pooling and control over PgBouncer configuration.

```
database_proxy_mode = "pgbouncer"
```

This value is an example. Confirm that it matches the options implemented by your root module.

### Option 2: Amazon RDS Proxy

Use AWS-managed RDS Proxy when you prefer a managed connection-pooling service.

```
database_proxy_mode = "rds-proxy"
```

RDS Proxy reduces the operational burden of managing proxy instances, operating-system updates, and proxy capacity.

### Option 3: Disable the Proxy

To connect application services directly to the database:

```
database_proxy_mode = "none"
```

Disabling the proxy removes the connection-pooling layer, so ensure that application connection counts remain within the database's available capacity.

> **Note:** The values above work only if the root Terraform module defines and implements these options. Update the examples if the actual variable uses different accepted values.

## Production Configuration Notes

### 1\. Amazon Machine Image (AMI)

The EC2 launch template currently uses an Amazon Linux 2-compatible base AMI.

Before deploying, ensure that `image_id` references a valid, supported AMI in the target AWS region.

For production deployments:

- Prefer a maintained AMI with a documented patching process.
- Pin or otherwise control AMI selection to support predictable deployments.
- Confirm that the bootstrap process installs and configures PgBouncer successfully.
- Plan for regular security updates and instance replacement.

Do not assume that an AMI ID is valid across all AWS regions.

### 2\. PostgreSQL Authentication

The configuration currently uses:

```
auth_type = md5
```

This may be suitable for a bootstrap configuration, but authentication should be reviewed against your organization's security requirements.

For stronger authentication controls, consider PostgreSQL SCRAM authentication where supported, or a properly configured `auth_user` and `auth_query` design.

Ensure that PgBouncer's authentication method is compatible with the PostgreSQL server configuration and the credentials used by application services.

### 3\. Database Network Security

Keep Amazon RDS for PostgreSQL private.

Recommended controls include:

- Disable public accessibility on the database.
- Allow PostgreSQL traffic only from approved application or PgBouncer security groups.
- Restrict access to the internal NLB and PgBouncer instances.
- Avoid broad inbound rules such as unrestricted access from `0.0.0.0/0`.
- Use TLS for database connections where supported and configured.

### 4\. Secrets Management and Credential Rotation

Use AWS Secrets Manager to store database credentials rather than embedding passwords in Terraform files, launch templates, or application configuration committed to source control.

For production workloads:

- Use a dedicated, least-privilege PostgreSQL application account.
- Grant only the database permissions required by the application.
- Restrict the EC2 instance role to the specific secrets it needs.
- Implement a credential-rotation procedure.
- Ensure PgBouncer can refresh or reload credentials appropriately after rotation.

Credential rotation must account for existing pooled connections and the behavior of the application during credential changes.

### 5\. Application Connection Strings

Application services should connect to the **internal NLB endpoint for PgBouncer**, rather than directly to the RDS endpoint, when PgBouncer is the selected connection-pooling layer.

The logical connection path is:

```
Application
    |
    v
Internal NLB DNS Name
    |
    v
PgBouncer
    |
    v
RDS PostgreSQL Endpoint
```

The application connection string should use the NLB DNS name and the listener port configured for PgBouncer.

The database host configured inside PgBouncer should point to the appropriate RDS PostgreSQL endpoint.

When RDS Proxy is selected instead, applications should use the RDS Proxy endpoint. When proxying is disabled, applications should use the database endpoint directly.

### 6\. Connection Pool Sizing

PgBouncer pool settings should be based on observed workload behavior rather than arbitrary defaults.

Review parameters such as:

- `pool_mode`
- `default_pool_size`
- `min_pool_size`
- `reserve_pool_size`
- `max_client_conn`
- `server_idle_timeout`
- `query_wait_timeout`

The appropriate settings depend on the number of application clients, database capacity, transaction duration, and connection usage patterns.

Monitor connection utilization, waiting clients, pool saturation, and PostgreSQL connection limits before increasing pool sizes.

Remember that increasing PgBouncer's client connection limit does not automatically increase the number of database connections PostgreSQL can safely support.

## Deployment Checklist

Before applying the module, verify the following:

- [ ]The EC2 AMI is valid and supported in the target region.
- [ ]The PgBouncer instances run in private subnets.
- [ ]The NLB is internal and targets healthy PgBouncer instances.
- [ ]The Auto Scaling Group spans the intended Availability Zones.
- [ ]Security groups allow only the required application and database traffic.
- [ ]IAM permissions follow the principle of least privilege.
- [ ]Database credentials are stored in AWS Secrets Manager.
- [ ]PostgreSQL remains private and is not publicly accessible.
- [ ]TLS requirements are configured and tested.
- [ ]PgBouncer authentication is compatible with the database configuration.
- [ ]CloudWatch logging and health monitoring are configured.
- [ ]Pool sizes and connection limits have been reviewed against expected workloads.
- [ ]Application connection strings point to the correct endpoint for the selected proxy mode.
- [ ]Failover, scaling, credential rotation, and recovery procedures have been tested.

## EC2 vs. EKS Deployment

This module describes the **EC2-based PgBouncer deployment pattern**. It is not the Kubernetes-based implementation.

| Capability | EC2 deployment | EKS deployment |
| --- | --- | --- |
| Compute | EC2 instances | Kubernetes pods |
| Scaling | Auto Scaling Group | Kubernetes workload scaling |
| Load balancing | Internal NLB | Kubernetes service and/or NLB integration |
| Configuration | Instance bootstrap and configuration management | Kubernetes manifests, Helm, or GitOps |
| Operations | Instance lifecycle management | Kubernetes lifecycle management |
| Best suited for | Teams operating AWS infrastructure directly | Teams already running workloads on EKS |

An EKS implementation would require Kubernetes-specific configuration, such as deployments, services, probes, resource requests and limits, disruption controls, and secret-delivery integration.

## Summary

This module provides an EC2-based pattern for deploying PgBouncer behind a private internal Network Load Balancer, with an Auto Scaling Group for instance management and AWS services for credentials, permissions, and logging.

The key production priorities are private connectivity, least-privilege access, reliable health checks, secure authentication, appropriate TLS configuration, and connection-pool sizing based on real workload measurements.

For teams that prefer a managed AWS connection-pooling service, Amazon RDS Proxy is an alternative. For teams already operating Kubernetes, an EKS-based PgBouncer deployment may be a better operational fit.

Suggested file location: `modules/pgbouncer/README.md`

One final detail: the `database_proxy_mode` values are documented as examples because the README alone does not confirm the exact values accepted by your root Terraform module. Verify those values against `variables.tf` before publishing the documentation.
