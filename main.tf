terraform {
  required_providers {
    aws = "~> 5.0"
  }
}
provider "aws" {
  region = "us-east-1"
}


data "archive_file" "get_devices_lambda_archive" {
  type        = "zip"
  source_file = "getDevices/index.mjs"
  output_path = "get_devices_lambda.zip"
}

data "archive_file" "add_user_lambda_archive" {
  type        = "zip"
  source_file = "addUser/index.mjs"
  output_path = "add_user_lambda.zip"
}
################
data "archive_file" "get_logs_lambda_archive" {
  type        = "zip"
  source_file = "getLogs/index.mjs"
  output_path = "get_logs_lambda.zip"
}

data "archive_file" "get_users_lambda_archive" {
  type        = "zip"
  source_file = "getUsers/index.mjs"
  output_path = "get_users_lambda.zip"
}

data "archive_file" "set_state_lambda_archive" {
  type        = "zip"
  source_file = "setState/index.mjs"
  output_path = "set_state_lambda.zip"
}

data "archive_file" "get_state_lambda_archive" {
  type        = "zip"
  source_file = "getState/index.mjs"
  output_path = "get_state_lambda.zip"
}


data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  name   = "dynamodb_access_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:DescribeTable",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
        "dynamodb:UpdateTable"
      ],
      "Resource": [
        "${aws_dynamodb_table.Users.arn}",
        "${aws_dynamodb_table.Devices.arn}",
        "${aws_dynamodb_table.Logs.arn}"
        ]
    }
  ]
}
EOF
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}



# policy attachments

resource "aws_iam_role_policy_attachment" "dynamodb_access_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}


# Create Lambda Functions

resource "aws_lambda_function" "lambda_get_devices" {
  function_name    = "getDevices"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.get_devices_lambda_archive.output_path
  source_code_hash = data.archive_file.get_devices_lambda_archive.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
}

resource "aws_lambda_function" "lambda_add_user" {
  function_name    = "addUser"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.add_user_lambda_archive.output_path
  source_code_hash = data.archive_file.add_user_lambda_archive.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
}

resource "aws_lambda_function" "lambda_get_logs" {
  function_name    = "getLogs"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.get_logs_lambda_archive.output_path
  source_code_hash = data.archive_file.get_logs_lambda_archive.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
}

resource "aws_lambda_function" "lambda_get_users" {
  function_name    = "getUsers"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.get_users_lambda_archive.output_path
  source_code_hash = data.archive_file.get_users_lambda_archive.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
}

resource "aws_lambda_function" "lambda_set_state" {
  function_name    = "setState"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.set_state_lambda_archive.output_path
  source_code_hash = data.archive_file.set_state_lambda_archive.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
}

resource "aws_lambda_function" "lambda_get_state" {
  function_name    = "getState"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.get_state_lambda_archive.output_path
  source_code_hash = data.archive_file.get_state_lambda_archive.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
}


# Create DynamoDB Tables

resource "aws_dynamodb_table" "Users" {
  name         = "Users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "Devices" {
  name         = "Devices"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "Logs" {
  name         = "Logs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_apigatewayv2_api" "project_assembler_api" {
  name          = "project_assembler_api"
  protocol_type = "HTTP"
  #target        = "[${aws_lambda_function.lambda_get_devices.invoke_arn}, ${aws_lambda_function.lambda_add_user.invoke_arn}, ${aws_lambda_function.lambda_get_logs.invoke_arn}, ${aws_lambda_function.lambda_get_users.invoke_arn}, ${aws_lambda_function.lambda_set_state.invoke_arn}, ${aws_lambda_function.lambda_get_state.invoke_arn}]"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.project_assembler_api.id
  name        = "default"
  auto_deploy = true
}



# Create Lambda function integrations
resource "aws_apigatewayv2_integration" "get_devices_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_get_devices.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "add_user_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_add_user.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "get_logs_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_get_logs.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "get_users_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_get_users.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "set_state_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_set_state.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "get_state_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_get_state.invoke_arn
  integration_method = "POST"
}



# Create API Gateway V2 routes
resource "aws_apigatewayv2_route" "get_devices_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /getDevices"
  target    = "integrations/${aws_apigatewayv2_integration.get_devices_integration.id}"
}

resource "aws_apigatewayv2_route" "add_user_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /addUser"
  target    = "integrations/${aws_apigatewayv2_integration.add_user_integration.id}"
}

resource "aws_apigatewayv2_route" "get_logs_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /getLogs"
  target    = "integrations/${aws_apigatewayv2_integration.get_logs_integration.id}"
}

resource "aws_apigatewayv2_route" "get_users_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /getUsers"
  target    = "integrations/${aws_apigatewayv2_integration.get_users_integration.id}"
}

resource "aws_apigatewayv2_route" "set_state_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /setState"
  target    = "integrations/${aws_apigatewayv2_integration.set_state_integration.id}"
}

resource "aws_apigatewayv2_route" "get_state_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /getState"
  target    = "integrations/${aws_apigatewayv2_integration.get_state_integration.id}"
}



# Create Lambda function permissions for API Gateway
resource "aws_lambda_permission" "get_devices_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_devices.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/getDevices"
}

resource "aws_lambda_permission" "add_user_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_add_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/addUser"

}

resource "aws_lambda_permission" "get_logs_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_logs.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/getLogs"
}

resource "aws_lambda_permission" "get_users_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_users.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/getUsers"
}

resource "aws_lambda_permission" "set_state_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_set_state.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/setState"
}

resource "aws_lambda_permission" "get_state_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_state.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/getState"
}

/*
aws_apigatewayv2_api.project_assembler_api.execution_arn
target        = "[${aws_lambda_function.lambda_get_devices.invoke_arn}, ${aws_lambda_function.lambda_add_user.invoke_arn}, ${aws_lambda_function.lambda_get_logs.invoke_arn}, ${aws_lambda_function.lambda_get_users.invoke_arn}, ${aws_lambda_function.lambda_set_state.invoke_arn}, ${aws_lambda_function.lambda_get_state.invoke_arn}]"
statement_id  = "AllowExecutionFromAPIGateway"
statement_id  = "AllowAPIGatewayInvokeGetProjects"
*/
