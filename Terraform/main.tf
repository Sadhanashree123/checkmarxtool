provider "aws" {
  region = var.aws_region
}

# Create an EKS cluster
module "eks_cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  subnets         = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]  
  vpc_id          = "vpc-xxxxxxxxxxxxxxxxx" 
  cluster_version = "1.21" 
}

# Create an ECR repository
resource "aws_ecr_repository" "ecr_repo" {
  name = var.ecr_repository_name
}
