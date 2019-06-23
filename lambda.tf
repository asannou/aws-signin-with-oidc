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

