output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "eks_node_security_group_id" {
  value = module.eks.node_security_group_id
}

##Security Group ID for the dynamically generated ALB
output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend_sg.id
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}
# output "db_endpoint" {
#   description = "RDS connection endpoint"
#   value       = module.rds.db_instance_endpoint
# }

output "db_port" {
  description = "RDS port"
  value       = module.rds.db_instance_port
}

output "db_name" {
  description = "DB name"
  value       = module.rds.db_instance_name
}

output "db_username" {
  description = "Master username"
  value       = module.rds.db_instance_username
  sensitive   = true
}


output "alb_irsa_role_arn" {
  value = module.alb_irsa.iam_role_arn
}

output "ecr_repositories" {
  value = [for r in aws_ecr_repository.repos : r.repository_url]
}
