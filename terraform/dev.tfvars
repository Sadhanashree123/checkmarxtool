region = "us-west-2"
cluster-name = "dev-cluster"
scaling = {
  desired = 2
  max     = 3
  min     = 1
}
ecr_repository_name  = "mydevsecopsdev-ecr"
sg_name = "dev_kube_sg"
subnets = ["10.0.2.0/24", "10.0.3.0/24"]
tags = {
  archuuid = "your-dev-archuuid"
  env      = "production"
}
vpc_cidr = "10.0.0.0/16"
workstation-external-cidr = "0.0.0.0/0"
