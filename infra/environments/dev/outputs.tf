############VPC OUTPUTS###########
output "vpc_id"                 { 
    value = module.vpc.vpc_id 
    }
output "private_subnets"        { 
    value = module.vpc.private_subnets 
    }
output "public_subnets"         { 
    value = module.vpc.public_subnets 
    }
output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}

output "internet_gateway_id" {
  value = module.vpc.igw_id
}





##############CLUSTER############

output "cluster_name"           { 
    value = module.eks.cluster_name 
    }
output "cluster_oidc_provider"  { 
    value = module.eks.oidc_provider_arn 
    }
output "node_sg_id"             { 
    value = module.eks.node_security_group_id
     }




output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "eks_node_role_arn" {
  value = module.eks.node_groups["on_demand"].iam_role_arn
}
# cluster_endpoint is needed to configure kubectl.
# cluster_security_group_id is useful if other resources (like RDS) need to reference it.

#############ECR#########################

output "ecr_frontend_repo_url" {
  value = aws_ecr_repository.repos["frontend"].repository_url
}

output "ecr_backend_repo_url" {
  value = aws_ecr_repository.repos["backend"].repository_url
}

################RDS##############
output "rds_endpoint"           { value = module.rds.db_instance_address }
output "rds_db_name"            { value = module.rds.db_instance_name }
output "rds_port" {
  value = module.rds.db_instance_port
}

output "rds_security_group_ids" {
  value = module.rds.db_security_group_ids
}

