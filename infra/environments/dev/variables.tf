variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "owner" {
  description = "Owner of resources"
  type        = string
}

#vpc Networking variable
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

#EKS Variables
variable "eks_version" {
  description = "EKS cluster version"
  type        = string
}

variable "node_instance_type" {
  description = "EKS worker node instance type"
  type        = string
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

#DB Variable
variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

#ECR Variable
variable "ecr_repos" {
  description = "List of ECR repositories"
  type        = list(string)
}

variable "image_retention_count" {
  description = "Number of images to keep in ECR"
  type        = number
}

variable "image_tag_mutability" {
  description = "ECR image tag mutability"
  type        = string
  default     = "MUTABLE" #Whether image tags can be overwritten
}

variable "force_delete" {
  description = "Force delete ECR repository if not empty"
  type        = bool
  default     = false #Whether Terraform should force delete the ECR repository even if it’s not empty
}
