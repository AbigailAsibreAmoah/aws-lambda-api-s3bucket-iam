# Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "lambda-api-demo"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lambda_timeout" {
  description = "Lambda function timeout"
  type        = number
  default     = 30
}