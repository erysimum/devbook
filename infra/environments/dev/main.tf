#############################################
# BACKEND CONFIG (REMOTE STATE IN S3)
#############################################
terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

#############################################
# FETCH AVAILABLE AVAILABILITY ZONES
#############################################
data "aws_availability_zones" "available" {}

#############################################
# GLOBAL TAGS
#############################################
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

#############################################
# VPC - PUBLIC / PRIVATE / DATABASE SUBNETS
#############################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "${var.project_name}-${var.env}-vpc"
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets  = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
  database_subnets = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i + 20)]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_support = true
  enable_dns_hostnames = true

  public_subnet_tags = merge(local.common_tags, {
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${var.project_name}-eks-${var.env}" = "shared"
  })

  private_subnet_tags = merge(local.common_tags, {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/${var.project_name}-eks-${var.env}" = "shared"
  })

  database_subnet_tags = merge(local.common_tags, { tier = "database" })
  tags                 = local.common_tags
}

#############################################
# EKS CLUSTER
#############################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = "${var.project_name}-eks-${var.env}"
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    on_demand = {
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      capacity_type  = "ON_DEMAND"
      subnet_ids     = module.vpc.private_subnets

      labels = {
        workload  = "general"
        lifecycle = "on-demand"
      }

      # tags = merge(local.common_tags, {
      #   "kubernetes.io/cluster/${var.project_name}-eks-${var.env}" = "owned"
      #   "kubernetes.io/role/elb" = "1"
      #   "kubernetes.io/role/internal-elb" = "1"
      # })
    }
  }

  tags = local.common_tags
}

#############################################
# AWS LOAD BALANCER CONTROLLER IRSA
#############################################
module "alb_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.project_name}-alb-controller-${var.env}"
  attach_policy_arns = [
    "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
  ]

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.common_tags
}



resource "kubernetes_service_account" "alb_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.alb_irsa.iam_role_arn
    }
  }
}

#############################################
# SECURITY GROUPS
#############################################

# ALB SG (PUBLIC)
resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-alb-sg-${var.env}"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# BACKEND SERVICE SG (ALB → BACKEND)
resource "aws_security_group" "backend_sg" {
  name   = "${var.project_name}-backend-sg-${var.env}"
  vpc_id = module.vpc.vpc_id

  ingress {
    description              = "Allow traffic from ALB"
    from_port                = 3000
    to_port                  = 3000
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.alb_sg.id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

#############################################
# RDS PARAMETER GROUP
#############################################
resource "aws_db_parameter_group" "postgres_params" {
  name        = "${var.project_name}-pg-params-${var.env}"
  family      = "postgres16"
  description = "Custom PostgreSQL params for application"

  parameters = [
    { name = "max_connections", value = "200" },
    { name = "log_min_duration_statement", value = "500" }
  ]

  tags = local.common_tags
}

#############################################
# RDS SUBNET GROUP
#############################################
module "db_subnet_group" {
  source  = "terraform-aws-modules/rds/aws//modules/db_subnet_group"
  version = "~> 6.5"

  name       = "${var.project_name}-db-subnets-${var.env}"
  subnet_ids = module.vpc.database_subnets

  tags = local.common_tags
}

#############################################
# RDS SECURITY GROUP
#############################################
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name   = "${var.project_name}-db-sg-${var.env}"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "Allow EKS worker nodes to access RDS"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.eks.node_security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = local.common_tags
}

#############################################
# RDS INSTANCE
#############################################
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier = "${var.project_name}-db-${var.env}"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t4g.micro"
  allocated_storage = 20
  storage_encrypted    = true
  multi_az             = false
  publicly_accessible  = false

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = module.db_subnet_group.db_subnet_group_name
  vpc_security_group_ids = [module.db_sg.security_group_id]
  parameter_group_name   = aws_db_parameter_group.postgres_params.name

  skip_final_snapshot = false

  tags = local.common_tags
}

#############################################
# ECR REPOSITORIES
#############################################
locals {
  ecr_lifecycle = jsonencode({
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
  for_each = toset(var.ecr_repos)

  name                 = "${var.project_name}-${each.value}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  lifecycle_policy {
    policy = local.ecr_lifecycle
  }

  tags = local.common_tags
}
