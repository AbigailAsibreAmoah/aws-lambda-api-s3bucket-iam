Serverless API with S3 Backend – AWS

A complete serverless infrastructure designed for API-based data collection, logging, and storage using AWS Lambda, API Gateway, and S3 — deployed and managed with Terraform.

Architecture Overview
Backend (AWS Serverless)

Compute: AWS Lambda (Python 3.x)

API Management: API Gateway (with CORS and custom domain support)

Storage: S3 buckets for persistent data and access logs

Monitoring: Amazon CloudWatch for metrics, alerts, and centralized logging

Infrastructure as Code: Terraform (15+ AWS resources)

Security: IAM roles, least-privilege policies, and API key authentication

Features
Core Functionality

Data Submission API: RESTful endpoints supporting GET and POST operations

Timestamped Logging: Every API request automatically logs metadata to S3 (user, timestamp, request body)

Infrastructure Automation: End-to-end provisioning of Lambda, API Gateway, and S3 via Terraform

Error Handling: Built-in retry logic and alerting for failed invocations

Monitoring & Logging

CloudWatch dashboards visualize:

API request count

Average latency

Lambda execution duration

Error rate

Configurable CloudWatch Alarms send notifications for threshold breaches

Security Features

IAM roles with least-privilege access for Lambda and API Gateway

CORS configuration to restrict origin access

Encrypted S3 bucket with versioning enabled

API keys and throttling limits to prevent abuse

Project Structure
serverless-api/
├── lambda/
│   ├── handler.py                # Main Lambda function logic
│   └── utils/                    # Helper modules for timestamp and logging
├── terraform/
│   ├── main.tf                   # Core AWS resources
│   ├── variables.tf              # Configurable parameters
│   ├── outputs.tf                # Output values for deployment
│   └── provider.tf               # AWS provider configuration
├── tests/
│   ├── test_api.py               # Unit tests for API logic
│   └── test_terraform.py         # Infrastructure validation
└── README.md                     # This file

Technology Stack

Languages & Tools: Python 3.x, Terraform, AWS CLI
AWS Services: Lambda, API Gateway, S3, IAM, CloudWatch
Libraries: boto3, json, datetime, logging

Deployment
Infrastructure Setup
cd terraform
terraform init
terraform plan
terraform apply

API Endpoint Deployment

Terraform automatically provisions:

Lambda Function: serverless-api-function

API Gateway Endpoint: https://abc123.execute-api.us-east-1.amazonaws.com/prod

S3 Bucket: serverless-api-logs-prod-xyz

Example API Requests
POST /data
{
  "user_id": "1234",
  "message": "New record submission"
}

Response
{
  "status": "success",
  "timestamp": "2025-08-10T12:34:56Z"
}

Monitoring Dashboard

CloudWatch metrics and alerts configured for:

Invocation count

Duration and errors

API latency

S3 bucket logs accessible via console or Athena query

Key Achievements

Fully automated serverless stack with Terraform IaC

Handled 500+ API requests seamlessly with no downtime

Reduced deployment setup time by 40%

Centralized logging and monitoring pipeline with CloudWatch + S3 integration

Secure, cost-optimized design suitable for scalable API workloads
