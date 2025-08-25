# Outputs
output "api_gateway_url" {
  description = "Base URL for API Gateway stage"
  value       = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.lambda_stage.stage_name}"
}

output "api_endpoint_get" {
  description = "GET endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.lambda_stage.stage_name}/data"
}

output "api_endpoint_post" {
  description = "POST endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.lambda_stage.stage_name}/data"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.lambda_backend.bucket
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.main_function.function_name
}