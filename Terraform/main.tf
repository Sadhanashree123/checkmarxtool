provider "aws" {
  region = var.aws_region
}
# Create an ECR repository
resource "aws_ecr_repository" "ecr_repo" {
 name                 = var.ecr_repository_name
 image_tag_mutability = "IMMUTABLE"

 image_scanning_configuration {
   scan_on_push = true
 }
}

