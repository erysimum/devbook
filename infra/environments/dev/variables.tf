variable "project_name" {
  description = "Project name for naming and tagging"
  type        = string
}

variable "env" {
  description = "Environment (e.g. dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "region" {
  description = "Region"
  type        = string
  default     = "ap-southeast-2"
}

variable "owner" {
  description = "Owner or team responsible for the resources"
  type        = string
  default     = "DevOpsTeam"
}




#######################################################
##########EKS#####################################
variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "Default EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "enable_public_endpoint" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = false
}

variable "use_bottlerocket" {
  description = "Use Bottlerocket AMI instead of AL2"
  type        = bool
  default     = false
}

############ECR############
variable "ecr_repos" {
  type    = list(string)
  default = ["frontend", "backend"]
  description = "List of ECR repositories to create"
}

variable "image_retention_count" {
  type    = number
  default = 2
  description = "Number of images to keep in ECR"
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}
variable "force_delete" {
  type    = bool
  default = true
}

######################################
variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "devbook"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "devbook"
}

variable "db_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
}