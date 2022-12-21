terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.76.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "./lambda/check_cert.py"
  output_path = "./lambda/check_cert.py.zip"
}

module "terraform-aws-lambda-function" {
  source  = "mineiros-io/lambda-function/aws"
  version = "0.5.0"

  function_name = "check_cert"
  description   = "Python Lambda Function that returns certification expiration info."
  filename      = "lambda/check_cert.py.zip"
  runtime       = "python3.9"
  handler       = "check_cert.lambda_handler"

  timeout     = 30
  memory_size = 128

  role_arn = module.iam_role.role.arn

  module_tags = {
    Environment = "Dev"
  }
}

module "iam_role" {
  source  = "mineiros-io/iam-role/aws"
  version = "~> 0.6.0"

  name = "python-function"

  assume_role_principals = [
    {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  ]

  tags = {
    Environment = "Dev"
  }
}

resource "aws_api_gateway_rest_api" "check_cert_api" {
  name        = "check_cert_api"
  description = "Terraform Serverless Application Example"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.check_cert_api.id
  parent_id   = aws_api_gateway_rest_api.check_cert_api.root_resource_id
  path_part   = "check_cert"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.check_cert_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.check_cert_api.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.terraform-aws-lambda-function.function.invoke_arn
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.terraform-aws-lambda-function.function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.check_cert_api.id}/*/${aws_api_gateway_method.proxy.http_method}${aws_api_gateway_resource.proxy.path}"
}