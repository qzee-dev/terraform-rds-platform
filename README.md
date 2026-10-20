# terraform-rds-platform

How to apply these ideas to your AWS PostgreSQL platform
Your current design uses RDS PostgreSQL, a Multi-AZ primary, two asynchronous read replicas, and RDS Proxy. Here is how I would approach replication lag without immediately changing databases.

1. Measure lag and its cause

Monitor ReplicaLag, primary write throughput, replica CPU and I/O, and long-running queries. In PostgreSQL, long-running queries on a hot standby can conflict with WAL replay, depending on the configuration.

2. Reduce replay bottlenecks

Investigate expensive queries, long-running read transactions, insufficient replica capacity, and storage throughput. Scale replica instances if the evidence shows resource saturation. Increasing instance size alone will not fix every cause.

3. Prevent stale reads

Route read-after-write requests to the primary, or implement a consistency-aware mechanism that waits for a replica to replay the relevant commit position before reading. RDS Proxy connection pooling alone does not provide this guarantee.

4. Consider change-data capture when appropriate

If your real requirement is distributing changes to caches, search indexes, analytics systems, or other services, investigate PostgreSQL logical decoding and AWS Database Migration Service (DMS). This is closer to Uber's log-streaming approach than trying to eliminate all lag in a physical read replica.

One important distinction
There is no single setting you can add to terraform.tfvars that makes PostgreSQL replication synchronous, lag-free, and scalable without trade-offs.

Asynchronous replicas prioritize write availability and can lag.

Synchronous replication can improve durability guarantees but may increase write latency or reduce write availability when synchronous standbys are unavailable.

Log-based change-data capture is useful for distributing changes to other systems, but does not automatically make ordinary RDS read replicas current.
