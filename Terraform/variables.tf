variable "bucket_name" {
     description = "Name of the S3 bucket"
     type        = string
   }

   variable "lambda_function_name" {
     description = "Name of the Lambda function"
     type        = string
   }

   variable "api_gateway_name" {
     description = "Name of the API Gateway"
     type        = string
   }

   variable "region" {
     description = "AWS region"
     type        = string
   }