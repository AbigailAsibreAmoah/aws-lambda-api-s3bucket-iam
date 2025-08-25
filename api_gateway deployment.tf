# Lambda permissions for API Gateway - GET
resource "aws_lambda_permission" "api_gateway_get" {
  statement_id  = "AllowExecutionFromAPIGatewayGET"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}

# Lambda permissions for API Gateway - POST
resource "aws_lambda_permission" "api_gateway_post" {
  statement_id  = "AllowExecutionFromAPIGatewayPOST"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "lambda_deployment" {
  depends_on = [
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.post_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id

  # Force new deployment on configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.lambda_resource.id,
      aws_api_gateway_method.get_method.id,
      aws_api_gateway_method.post_method.id,
      aws_api_gateway_integration.get_integration.id,
      aws_api_gateway_integration.post_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage (replaces deprecated stage_name)
resource "aws_api_gateway_stage" "lambda_stage" {
  deployment_id = aws_api_gateway_deployment.lambda_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  stage_name    = "prod"
}