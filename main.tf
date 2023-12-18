terraform {
  required_providers {
    aws = "~> 5.0"
  }
}
provider "aws" {
  region = "us-east-1"
}


data "archive_file" "get_projects_lambda_archive" {
  type        = "zip"
  source_file = "getProjects/index.mjs"
  output_path = "get_projects_lambda.zip"
}

data "archive_file" "add_user_lambda_archive" {
  type        = "zip"
  source_file = "addUser/index.mjs"
  output_path = "add_user_lambda.zip"
}

data "archive_file" "get_project_of_interest_lambda_archive" {
  type        = "zip"
  source_file = "getProjectOfInterest/index.mjs"
  output_path = "get_project_of_interest_lambda.zip"
}

data "archive_file" "get_users_lambda_archive" {
  type        = "zip"
  source_file = "getUsers/index.mjs"
  output_path = "get_users_lambda.zip"
}

data "archive_file" "add_participant_lambda_archive" {
  type        = "zip"
  source_file = "addParticipant/index.mjs"
  output_path = "add_participant_lambda.zip"
}

data "archive_file" "add_project_lambda_archive" {
  type        = "zip"
  source_file = "addProject/index.mjs"
  output_path = "add_project_lambda.zip"
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
        "${aws_dynamodb_table.Projects.arn}"
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

resource "aws_lambda_function" "lambda_get_projects" {
  function_name    = "getProjects"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.get_projects_lambda_archive.output_path
  source_code_hash = data.archive_file.get_projects_lambda_archive.output_base64sha256
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

resource "aws_lambda_function" "lambda_get_project_of_interest" {
  function_name    = "getProjectOfInterest"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.get_project_of_interest_lambda_archive.output_path
  source_code_hash = data.archive_file.get_project_of_interest_lambda_archive.output_base64sha256
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

resource "aws_lambda_function" "lambda_add_participant" {
  function_name    = "addParticipant"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.add_participant_lambda_archive.output_path
  source_code_hash = data.archive_file.add_participant_lambda_archive.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
}

resource "aws_lambda_function" "lambda_add_project" {
  function_name    = "addProject"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.add_project_lambda_archive.output_path
  source_code_hash = data.archive_file.add_project_lambda_archive.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
}


# Create DynamoDB Tables

resource "aws_dynamodb_table" "Users" {
  name         = "Users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"
  attribute {
    name = "email"
    type = "S"
  }
}

resource "aws_dynamodb_table" "Projects" {
  name         = "Projects"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "projectID"
  attribute {
    name = "projectID"
    type = "S"
  }
}



resource "aws_apigatewayv2_api" "project_assembler_api" {
  name          = "project_assembler_api"
  protocol_type = "HTTP"
  #target        = "[${aws_lambda_function.lambda_get_projects.invoke_arn}, ${aws_lambda_function.lambda_add_user.invoke_arn}, ${aws_lambda_function.lambda_get_project_of_interest.invoke_arn}, ${aws_lambda_function.lambda_get_users.invoke_arn}, ${aws_lambda_function.lambda_add_participant.invoke_arn}, ${aws_lambda_function.lambda_add_project.invoke_arn}]"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.project_assembler_api.id
  name        = "default"
  auto_deploy = true
}



# Create Lambda function integrations
resource "aws_apigatewayv2_integration" "get_projects_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_get_projects.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "add_user_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_add_user.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "get_project_of_interest_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_get_project_of_interest.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "get_users_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_get_users.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "add_participant_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_add_participant.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "add_project_integration" {
  api_id             = aws_apigatewayv2_api.project_assembler_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_add_project.invoke_arn
  integration_method = "POST"
}



# Create API Gateway V2 routes
resource "aws_apigatewayv2_route" "get_projects_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /getProjects"
  target    = "integrations/${aws_apigatewayv2_integration.get_projects_integration.id}"
}

resource "aws_apigatewayv2_route" "add_user_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /addUser"
  target    = "integrations/${aws_apigatewayv2_integration.add_user_integration.id}"
}

resource "aws_apigatewayv2_route" "get_project_of_interest_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /getProjectOfInterest"
  target    = "integrations/${aws_apigatewayv2_integration.get_project_of_interest_integration.id}"
}

resource "aws_apigatewayv2_route" "get_users_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /getUsers"
  target    = "integrations/${aws_apigatewayv2_integration.get_users_integration.id}"
}

resource "aws_apigatewayv2_route" "add_participant_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /addParticipant"
  target    = "integrations/${aws_apigatewayv2_integration.add_participant_integration.id}"
}

resource "aws_apigatewayv2_route" "add_project_route" {
  api_id    = aws_apigatewayv2_api.project_assembler_api.id
  route_key = "POST /addProject"
  target    = "integrations/${aws_apigatewayv2_integration.add_project_integration.id}"
}



# Create Lambda function permissions for API Gateway
resource "aws_lambda_permission" "get_projects_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_projects.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/getProjects"
}

resource "aws_lambda_permission" "add_user_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_add_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/addUser"

}

resource "aws_lambda_permission" "get_project_of_interest_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_project_of_interest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/getProjectOfInterest"
}

resource "aws_lambda_permission" "get_users_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_users.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/getUsers"
}

resource "aws_lambda_permission" "add_participant_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_add_participant.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/addParticipant"
}

resource "aws_lambda_permission" "add_project_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_add_project.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.project_assembler_api.execution_arn}/*/*/addProject"
}

/*
aws_apigatewayv2_api.project_assembler_api.execution_arn
target        = "[${aws_lambda_function.lambda_get_projects.invoke_arn}, ${aws_lambda_function.lambda_add_user.invoke_arn}, ${aws_lambda_function.lambda_get_project_of_interest.invoke_arn}, ${aws_lambda_function.lambda_get_users.invoke_arn}, ${aws_lambda_function.lambda_add_participant.invoke_arn}, ${aws_lambda_function.lambda_add_project.invoke_arn}]"
statement_id  = "AllowExecutionFromAPIGateway"
statement_id  = "AllowAPIGatewayInvokeGetProjects"
*/
