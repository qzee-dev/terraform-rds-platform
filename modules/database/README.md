Database implementation considerations

The master password is sensitive, but Terraform still manages it in state. Use encrypted remote state, strict state access controls, and protected CI credentials.

The master secret is not automatically rotated by this configuration. Add and test a rotation workflow before production.

PostgreSQL read replicas replicate asynchronously; applications must account for replica lag.

The Multi-AZ primary and read replicas serve different purposes: availability and read scaling, respectively.

Confirm engine-version availability, supported instance classes, replica encryption behavior, and Performance Insights settings before deployment.
