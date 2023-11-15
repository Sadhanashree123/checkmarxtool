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
data "aws_availability_zones" "azs" {
    state = "available"
}
data "aws_availability_zones" "available" {}
locals {
    cluster_name = "EKS-Cluster"
}
module vpc {
    source = "terraform-aws-modules/vpc/aws"
    version = "3.2.0"
    name = "Demo-VPC"
    cidr = "10.0.0.0/16"
    azs = data.aws_availability_zones.available.names
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets =  ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    enable_nat_gateway = true
    single_nat_gateway = true
tags = {
    "Name" = "Demo-VPC"
}
public_subnet_tags = {
    "Name" = "Demo-Public-Subnet"
}
private_subnet_tags = {
    "Name" = "Demo-Private-Subnet"
}
}
resource "aws_security_group" "worker_group_mgmt_one" {
    name_prefix = "worker_group_mgmt_one"
    vpc_id = module.vpc.vpc_id
ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
cidr_blocks = [
            "10.0.0.0/8"
        ]
    }
}
resource "aws_security_group" "worker_group_mgmt_two" {
    name_prefix = "worker_group_mgmt_two"
    vpc_id = module.vpc.vpc_id
 
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
cidr_blocks = [
            "10.0.0.0/8"
        ]
    }
}
resource "aws_security_group" "all_worker_mgmt" {
    name_prefix = "all_worker_management"
    vpc_id = module.vpc.vpc_id
ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
cidr_blocks = [
            "10.0.0.0/8"
        ]
    }
}
module "eks"{
    source = "terraform-aws-modules/eks/aws"
    version = "17.1.0"
    cluster_name = local.cluster_name
    cluster_version = "1.20"
    subnets = module.vpc.private_subnets
tags = {
        Name = "Demo-EKS-Cluster"
    }
vpc_id = module.vpc.vpc_id
    workers_group_defaults = {
        root_volume_type = "gp2"
    }
}
data "aws_eks_cluster" "cluster" {
    name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
    name = module.eks.cluster_id
}
provider "kubernetes" {
    host = data.aws_eks_cluster.cluster.endpoint
    token = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64encode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}
