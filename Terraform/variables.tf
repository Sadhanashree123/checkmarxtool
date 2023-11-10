variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name for the ECR repository"
  type        = string
}
