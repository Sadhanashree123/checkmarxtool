provider "aws" {
  region = var.region
}
# Create an ECR repository
resource "aws_ecr_repository" "ecr_repo" {
 name                 = var.ecr_repository_name
 image_tag_mutability = "IMMUTABLE"

 image_scanning_configuration {
   scan_on_push = true
 }
}
module "aws_vpc" {
  source          = "github.com/erozedguy/AWS-VPC-terraform-module.git"
  networking      = var.networking
  security_groups = var.security_groups
}
variable "networking" {
  type = object({
   cidr_block       = string
   vpc_name         = string
   azs              = list(string)
   public_subnets   = list(string)
   private_subnets  = list(string)
   nat_gateways     = bool
  })
  default = {
   cidr_block       = "10.0.0.0/16"
   vpc_name         = "terraform-vpc"
   azs              = ["us-east-1a", "us-east-1b"]
   public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
   private_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
   nat_gateways     = true
  }
}

variable "security_groups" {
  type = list(object({
    name        = string
    description = string
    ingress = object({
      description      = string
      protocol         = string
      from_port        = number
      to_port          = number
      cidr_blocks      = list(string)
      ipv6_cidr_blocks = list(string)
    })
  }))

  default = [{
    name        = "ssh"
    description = "Port 22"
    ingress = {
      description      = "Allow SSH access"
      protocol         = "tcp"
      from_port        = 22
      to_port          = 22
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
    }
  }]
}
resource "aws_iam_role" "EKSClusterRole" {
  name = "EKSClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role" "NodeGroupRole" {
  name = "EKSNodeGroupRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {

        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.EKSClusterRole.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.NodeGroupRole.name
}
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.NodeGroupRole.name
}
resource "aws_eks_cluster" "eks-cluster" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.EKSClusterRole.arn
  version  = "1.21"

  vpc_config {
    subnet_ids          = flatten([ module.aws_vpc.public_subnets_id, module.aws_vpc.private_subnets_id ])
    security_group_ids  = flatten(module.aws_vpc.security_groups_id)
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}
resource "aws_eks_node_group" "node-ec2" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "t3_micro-node_group"
  node_role_arn   = aws_iam_role.NodeGroupRole.arn
  subnet_ids      = flatten( module.aws_vpc.private_subnets_id )

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  ami_type       = "AL2_x86_64"
  instance_types = ["t3.micro"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}
