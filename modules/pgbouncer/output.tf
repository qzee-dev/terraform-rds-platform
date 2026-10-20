output "endpoint" {
  description = "PgBouncer internal endpoint, exposed through the NLB DNS name."
  value       = aws_lb.pgbouncer.dns_name
}

output "security_group_id" {
  description = "PgBouncer security group ID."
  value       = aws_security_group.pgbouncer.id
}

output "target_group_arn" {
  description = "PgBouncer target group ARN."
  value       = aws_lb_target_group.pgbouncer.arn
}

output "asg_name" {
  description = "PgBouncer autoscaling group name."
  value       = aws_autoscaling_group.pgbouncer.name
}
