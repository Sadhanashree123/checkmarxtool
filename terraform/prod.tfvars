region = "us-west-2"
cluster-name = "prod-cluster"
scaling = {
  desired = 2
  max     = 3
  min     = 1
}
ecr_repository_name  = "mydevsecopsprod-ecr"
sg_name = "prod_kube_sg"
subnets = ["10.0.2.0/24", "10.0.3.0/24"]
tags = {
  archuuid = "your-prod-archuuid"
  env      = "production"
}
vpc_cidr = "10.0.0.0/16"
workstation-external-cidr = "0.0.0.0/0"
