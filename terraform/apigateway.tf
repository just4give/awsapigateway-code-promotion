data "aws_caller_identity" "current" {}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "serveless-rest-api"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "todos"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.resource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "response-200" {
  depends_on  = ["aws_api_gateway_method.method"]
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.resource.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.resource.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:027378352884:function:myTestLambda:$${stageVariables.lambdaAlias}/invocations"
}

resource "aws_api_gateway_integration_response" "integration-response" {
  depends_on  = ["aws_api_gateway_integration.integration"]
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.resource.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"

  status_code = "${aws_api_gateway_method_response.response-200.status_code}"

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  count         = "${length(var.alias)}"
  depends_on    = ["aws_lambda_alias.aliases"]
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "arn:aws:lambda:us-east-1:027378352884:function:myTestLambda:${element(var.alias, count.index)}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}


resource "aws_api_gateway_deployment" "dev" {
  depends_on  = ["aws_api_gateway_integration.integration"]
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${lower(element(var.alias, 0))}"

  variables = {
    "lambdaAlias" = "${element(var.alias, 0)}"
    "deployed_at" = "${timestamp()}"
  }
}

resource "aws_api_gateway_deployment" "prod" {
  depends_on  = ["aws_api_gateway_deployment.dev"]
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${lower(element(var.alias, 1))}"

  variables = {
    "lambdaAlias" = "${element(var.alias, 1)}"
    "deployed_at" = "${timestamp()}"
  }
}

output "invoke_urls_dev" {
  value = "${aws_api_gateway_deployment.dev.invoke_url}"
}

output "invoke_urls_prod" {
  value = "${aws_api_gateway_deployment.prod.invoke_url}"
}
