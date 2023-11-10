provider "aws" {
     region = var.region
   }

   resource "aws_s3_bucket" "mybucket" {
     bucket = var.bucket_name
     acl    = "private"
   }

   resource "aws_lambda_function" "mylambda" {
     function_name = var.lambda_function_name
     handler      = "index.handler"
     runtime      = "nodejs14.x"
   }

   resource "aws_api_gateway_rest_api" "myapigateway" {
     name        = var.api_gateway_name
     description = "My API Gateway"
   }