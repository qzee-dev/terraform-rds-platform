Yes — absolutely.

You can use the PgBouncer endpoint as the database connection target for your application, whether the application runs in EKS or EC2. The app does not connect directly to RDS. It connects to PgBouncer, and PgBouncer connects to RDS behind the scenes.

The important thing is:
- app -> PgBouncer endpoint
- PgBouncer -> RDS primary
- optionally PgBouncer -> read replicas for read-only traffic

This is exactly the normal pattern for PgBouncer.

For EKS:
- Run PgBouncer in EKS as a private internal Service
- Or run PgBouncer in EC2 and expose it privately
- Then your app pods connect to the PgBouncer Service or private NLB DNS name

For EC2:
- Run PgBouncer in EC2 behind an internal NLB
- Then app servers connect to the NLB DNS name

The endpoint you get from output is the target your app should use, and it is not a direct database endpoint. It is the pooler endpoint.

Example app DSN:
- RDS direct: host=rds-primary.xxxxx.us-east-1.rds.amazonaws.com port=5432
- PgBouncer: host=pgbouncer.internal.local or host=pgbouncer-service.default.svc.cluster.local port=6432

That is the correct production architecture.

Important caveat:
- If you use transaction pooling, the app must be compatible with pooled transactions.
- If your app creates very short-lived DB connections, PgBouncer helps a lot.
- If your app holds long transactions or uses session-specific DB features, you must tune pool mode and application behavior carefully.

So the answer is:
- Yes, you can absolutely point the running application to a PgBouncer endpoint instead of direct RDS.
- Yes, this works the same way in EKS or EC2.
- No, it is not “starting from scratch” if you already have the DB and network foundation in place.

If you want, I can give you the EKS-ready version next with:
- Kubernetes Deployment
- Service
- ConfigMap
- Secret integration
- private networking
- readiness/liveness
- production settings for pool_mode and health checks
