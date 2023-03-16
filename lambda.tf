# data "archive_file" "vpc_function" {
#   type             = "zip"
#   source_file      = "${path.module}/lambda/vpc_function.py"
#   output_file_mode = "0666"
#   output_path      = "${path.module}/lambda/vpc_function.zip"
# }

# data "archive_file" "tgw_function" {
#   type             = "zip"
#   source_file      = "${path.module}/lambda/tgw_function.py"
#   output_file_mode = "0666"
#   output_path      = "${path.module}/lambda/tgw_function.zip"
# }

# resource "aws_iam_role" "iam_for_lambda" {
#   name = "iam_for_lambda"

#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Action" : "sts:AssumeRole",
#         "Resource" : "${var.lambda_iam_role_arn}",
#         "Effect" : "Allow",
#         "Sid" : ""
#       }
#     ]
#   })

#   inline_policy {
#     name = "dynamo_access_policy"

#     policy = jsonencode({
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Sid" : "Stmt1673299211793",
#           "Action" : [

#             "dynamodb:GetItem",
#             "dynamodb:Query",
#             "dynamodb:PutItem",
#             "dynamodb:UpdateItem"
#           ],
#           "Effect" : "Allow",
#           "Resource" : "test"
#         }
#       ]
#     })
#   }
# }

# # TODO: move lambdas out of the module when we move to Proton
# resource "aws_lambda_function" "vpc_function" {
#   # If the file is not in the current working directory you will need to include a
#   # path.module in the filename.
#   filename      = "${path.module}/lambda/vpc_function.zip"
#   function_name = "network_dynamodb_vpc_function-${local.unique_name}"
#   role          = var.lambda_iam_role_arn
#   handler       = "vpc_function.lambda_handler"

#   source_code_hash = data.archive_file.vpc_function.output_base64sha256

#   runtime = "python3.9"

#   depends_on = [
#     data.archive_file.vpc_function
#   ]
# }

# resource "aws_lambda_function" "tgw_function" {
#   # If the file is not in the current working directory you will need to include a
#   # path.module in the filename.
#   filename      = "${path.module}/lambda/tgw_function.zip"
#   function_name = "network_dynamodb_tgw_function-${local.unique_name}"
#   role          = var.lambda_iam_role_arn
#   handler       = "tgw_function.lambda_handler"

#   source_code_hash = data.archive_file.tgw_function.output_base64sha256

#   runtime = "python3.9"

#   environment {
#     variables = {
#       dynamo_table_key = jsonencode({"id": "network_vpc"})
#     }
#   }

#   depends_on = [
#     data.archive_file.tgw_function
#   ]
# }

# data "aws_lambda_invocation" "vpc_function" {
#   function_name = aws_lambda_function.vpc_function.function_name

#   input = jsonencode({
#     "dynamo_table_key" : jsonencode({ "id" : "${local.unique_name}" }),
#     "local_value" : jsonencode({
#       "id" : "${local.unique_name}",
#       "name" : "${local.name}",
#       "env" : "${var.env}",
#       "attributes" : {
#         "metadata" : "${local.vpc_metadata}",
#         "tgw_attachment_id" : "test"
#       }
#     })
#   })
# }

# resource "aws_lambda_invocation" "tgw_function" {
#   function_name = aws_lambda_function.tgw_function.function_name

#   input = jsonencode({})
# }
