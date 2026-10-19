Proxy security requirements

The proxy role needs permission to retrieve the secret and decrypt it using the customer-managed KMS key. The key policy must also allow the required access.

The secret must contain credentials compatible with the PostgreSQL database user.

This configuration uses Secrets Manager authentication; it does not enable IAM database authentication for application connections.

Verify the RDS Proxy PostgreSQL authentication requirements and CloudWatch metric dimensions against your selected AWS provider and service configuration.
