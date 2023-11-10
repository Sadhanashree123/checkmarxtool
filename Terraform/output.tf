output "s3_bucket_name" {
     value = aws_s3_bucket.mybucket.bucket
   }

   output "lambda_function_name" {
     value = aws_lambda_function.mylambda.function_name
   }

   output "api_gateway_url" {
     value = aws_api_gateway_rest_api.myapigateway.invoke_url
   }