resource "aws_lambda_function" "oidc" {
  filename = "${data.archive_file.lambda.output_path}"
  function_name = "UpdateOIDCProviderThumbprints"
  role = "${aws_iam_role.lambda.arn}"
  handler = "UpdateOIDCProviderThumbprints.handler"
  runtime = "nodejs8.10"
  timeout = "60"
  source_code_hash = "${base64sha256(file("${data.archive_file.lambda.output_path}"))}"
  environment {
    variables = {
      OIDC_PROVIDER_ARN = "${aws_iam_openid_connect_provider.google.arn}"
    }
  }
}

resource "aws_iam_role" "lambda" {
  name = "LambdaRoleOIDC"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-role.json}"
}

data "aws_iam_policy_document" "lambda-role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role = "${aws_iam_role.lambda.name}"
  policy_arn = "${aws_iam_policy.lambda.arn}"
}

resource "aws_iam_policy" "lambda" {
  name = "UpdateOIDCProviderGoogleThumbprint"
  path = "/"
  policy = "${data.aws_iam_policy_document.lambda.json}"
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint"
    ]
    resources = ["${aws_iam_openid_connect_provider.google.arn}"]
  }
}

data "archive_file" "lambda" {
  type = "zip"
  source_dir = "lambda"
  output_path = "lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda-log" {
  name = "/aws/lambda/${aws_lambda_function.oidc.function_name}"
  retention_in_days = 14
}

resource "aws_iam_role_policy_attachment" "lambda-log" {
  role = "${aws_iam_role.lambda.name}"
  policy_arn = "${aws_iam_policy.lambda-log.arn}"
}

resource "aws_iam_policy" "lambda-log" {
  name = "LogForUpdateOIDCProviderGoogleThumbprint"
  path = "/"
  policy = "${data.aws_iam_policy_document.lambda-log.json}"
}

data "aws_iam_policy_document" "lambda-log" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_lambda_permission" "cloudwatch" {
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.oidc.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.lambda.arn}"
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name = "UpdateOIDCProviderThumbprints"
  schedule_expression = "${var.lambda_schedule_expression}"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = "${aws_cloudwatch_event_rule.lambda.name}"
  arn = "${aws_lambda_function.oidc.arn}"
}

