terraform {
  backend "s3" {}   # values injected with: terraform init -backend-config=backend.hcl
}

provider "aws" {
  region = var.region
}

############################
# VPC (2 AZ, public+private, 1 NAT)
############################
##############################################
# VPC MODULE - Production Ready Best Practice
##############################################

# Fetch available AZs automatically
data "aws_availability_zones" "available" {}

# Common reusable tags for all resources
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  # Dynamic and descriptive VPC naming
  name = "${var.project_name}-${var.env}-vpc"

  # Configurable VPC CIDR
  cidr = var.vpc_cidr

  # Automatically pick the first two available AZs
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Dynamically calculate subnet CIDRs using cidrsubnet()
  public_subnets = [
    for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i)
  ]

  private_subnets = [
    for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]

  # High-availability NAT gateway setup (1 per AZ)
  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Tags for Kubernetes (EKS) subnet discovery
  public_subnet_tags = merge(local.common_tags, {
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${var.project_name}-eks-${var.env}" = "owned"
  })

  private_subnet_tags = merge(local.common_tags, {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/${var.project_name}-eks-${var.env}" = "owned"
  })

  # Apply common tags to all resources
  tags = local.common_tags
}


############################
# EKS (IRSA on, managed node group)
############################
############################
# EKS Module - Production Ready
############################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"  # use latest 20.x if available

  # Cluster configuration
  cluster_name    = "${var.project_name}-eks-${var.env}"
  cluster_version = var.eks_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  enable_irsa     = true

  # Cluster endpoint access
  cluster_endpoint_public_access  = var.env == "prod" ? false : true
  cluster_endpoint_private_access = true

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    on_demand = {
      ami_type       = var.use_bottlerocket ? "BOTTLEROCKET_x86_64" : "AL2_x86_64"
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      capacity_type  = "ON_DEMAND"
      subnet_ids     = module.vpc.private_subnets
      labels = {
        "workload"  = "general"
        "lifecycle" = "on-demand"
      }
      tags = merge(local.common_tags, {
        "kubernetes.io/cluster/${var.project_name}-eks-${var.env}" = "owned"
        "kubernetes.io/role/elb"                                   = "1"
        "kubernetes.io/role/internal-elb"                          = "1"
      })
    }

    # Uncomment this block if you want a Spot node group
    # spot = {
    #   ami_type       = var.use_bottlerocket ? "BOTTLEROCKET_x86_64" : "AL2_x86_64"
    #   instance_types = ["t3.small", "t3.medium"]
    #   desired_size   = 1
    #   min_size       = 0
    #   max_size       = 3
    #   capacity_type  = "SPOT"
    #   subnet_ids     = module.vpc.private_subnets
    #   labels = {
    #     "workload"  = "spot"
    #     "lifecycle" = "spot"
    #   }
    #   tags = merge(local.common_tags, {
    #     "kubernetes.io/cluster/${var.project_name}-eks-${var.env}" = "owned"
    #     "kubernetes.io/role/elb"                                   = "1"
    #     "kubernetes.io/role/internal-elb"                          = "1"
    #   })
    # }
  }

  # Tags applied to the cluster itself
  tags = merge(local.common_tags, {
    "Project"   = var.project_name
    "Env"       = var.env
    "ManagedBy" = "Terraform"
  })
}


############################
# ECR (frontend + backend repos)
############################

locals {
  ecr_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_retention_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_repository" "repos" {
  for_each = toset(var.ecr_repos)   # {"frontend,"backend"}
  #for_each = { for repo in var.ecr_repos : repo => repo }

  name                 = "${var.project_name}-${each.value}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete   

  encryption_configuration {
    encryption_type = "AES256"
  }

  lifecycle_policy {
    policy = local.ecr_lifecycle_policy
  }

  tags = local.common_tags

#   lifecycle {
#     prevent_destroy = true
#   }
}




############################
# RDS Postgres (dev-sized)
############################
###############################################################################
# Security Group for RDS
###############################################################################
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name   = "${var.project_name}-db-sg-${var.env}"
  vpc_id = module.vpc.vpc_id

  # Allow only EKS worker nodes to access Postgres (port 5432)
  ingress_with_source_security_group_id = [
    {
      description              = "Allow EKS worker nodes to access RDS"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.eks.node_security_group_id
    }
  ]

  # Allow outbound connections for maintenance/monitoring
  egress_rules = ["all-all"]

 tags = merge(local.common_tags, {
    "kubernetes.io/cluster/${var.project_name}-eks-${var.env}" = "owned"
  })
}

###############################################################################
# RDS Subnet Group
###############################################################################
module "db_subnet_group" {
  source  = "terraform-aws-modules/rds/aws//modules/db_subnet_group"
  version = "~> 6.5"

  name       = "${var.project_name}-db-subnets-${var.env}"
  subnet_ids = module.vpc.private_subnets
  tags       = local.common_tags
}

###############################################################################
# RDS PostgreSQL Database
###############################################################################
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier = "${var.project_name}-db-${var.env}"

  engine            = "postgres"
  engine_version    = "16.4"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = false

  # Networking
  vpc_security_group_ids = [module.db_sg.security_group_id]
  db_subnet_group_name   = module.db_subnet_group.db_subnet_group_name

  tags = local.common_tags
}