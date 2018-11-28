variable iam_for_lambda {}
variable lambda_func_name {}
variable aws_region {}

variable alias {
  type    = "list"
  default = ["DEV", "PROD"]
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.iam_for_lambda}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

data "archive_file" "lambdazip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda.zip"
}

resource "aws_lambda_function" "lambda_func" {
  filename         = "${path.module}/../lambda.zip"
  function_name    = "${var.lambda_func_name}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambdazip.output_md5}"
  runtime          = "nodejs8.10"
  timeout          = 10

  environment {
    variables = {
      ENV     = "DEV"
      API_KEY = "api_dev"
    }
  }
}

resource "aws_lambda_alias" "aliases" {
  count            = "${length(var.alias)}"
  name             = "${element(var.alias, count.index)}"
  description      = "lambda alias for ${element(var.alias, count.index)}"
  function_name    = "${aws_lambda_function.lambda_func.arn}"
  function_version = "$LATEST"
}

output "lambda_arn" {
  value = "${aws_lambda_function.lambda_func.arn}"
}

output "lambda_aliases" {
  value = ["${aws_lambda_alias.aliases.*.arn}"]
}
