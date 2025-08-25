provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "lambda-api-demo"
}

# S3 Bucket for Lambda backend storage
resource "aws_s3_bucket" "lambda_backend" {
  bucket = "${var.project_name}-backend-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "lambda_backend_versioning" {
  bucket = aws_s3_bucket.lambda_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Lambda execution policy attachment
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom IAM policy for S3 access
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${var.project_name}-lambda-s3-policy"
  description = "Policy for Lambda to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.lambda_backend.arn,
          "${aws_s3_bucket.lambda_backend.arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# Lambda function code (inline for demo)
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = <<-EOF
import json
import boto3
import datetime
import os

def lambda_handler(event, context):
    # Initialize S3 client
    s3 = boto3.client('s3')
    bucket_name = os.environ['S3_BUCKET']
    
    # Get HTTP method from event
    http_method = event.get('httpMethod', 'UNKNOWN')
    
    try:
        if http_method == 'GET':
            # Handle GET request
            response_data = {
                'message': 'Hello from Lambda GET!',
                'timestamp': datetime.datetime.now().isoformat(),
                'bucket': bucket_name
            }
            
            # Log to S3
            log_key = f"logs/get-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
            s3.put_object(
                Bucket=bucket_name,
                Key=log_key,
                Body=json.dumps(response_data),
                ContentType='application/json'
            )
            
        elif http_method == 'POST':
            # Handle POST request
            request_body = json.loads(event.get('body', '{}'))
            response_data = {
                'message': 'Data received via POST!',
                'received_data': request_body,
                'timestamp': datetime.datetime.now().isoformat(),
                'bucket': bucket_name
            }
            
            # Store data in S3
            data_key = f"data/post-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
            s3.put_object(
                Bucket=bucket_name,
                Key=data_key,
                Body=json.dumps(response_data),
                ContentType='application/json'
            )
            
        else:
            response_data = {
                'message': 'Method not supported',
                'method': http_method
            }
    
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_data)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Internal server error'
            })
        }
EOF
    filename = "lambda_function.py"
  }
}

# Lambda Function
resource "aws_lambda_function" "main_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-function"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.lambda_backend.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_s3_attachment,
    aws_s3_bucket.lambda_backend
  ]
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "${var.project_name}-api"
  description = "API Gateway for Lambda function"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway Resource
resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "data"
}

# API Gateway Method - GET
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Method - POST
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration - GET
resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.get_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main_function.invoke_arn
}

# API Gateway Integration - POST
resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.post_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main_function.invoke_arn
}

