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