provider "aws" {
  region = "${var.aws_region}"
}

data "aws_caller_identity" "aws" {}

resource "aws_iam_openid_connect_provider" "google" {
  url = "https://accounts.google.com"
  thumbprint_list = "${var.thumbprint["google"]}"
  client_id_list = ["${var.client_id["google"]}"]
}

resource "aws_s3_bucket" "web" {
  bucket = "${var.s3_bucket}"
}

resource "aws_s3_bucket_object" "google_html" {
  bucket = "${aws_s3_bucket.web.bucket}"
  key = "google"
  source = "google.html"
  content_type = "text/html"
  acl = "public-read"
}

data "template_file" "google_js" {
  template = "${file("google.js")}"
  vars {
    client_id = "${var.client_id["google"]}"
    invoke_url = "${aws_api_gateway_deployment.signin.invoke_url}"
  }
}

resource "aws_s3_bucket_object" "google_js" {
  bucket = "${aws_s3_bucket.web.bucket}"
  key = "google.js"
  content = "${data.template_file.google_js.rendered}"
  content_type = "application/javascript"
  acl = "public-read"
}

resource "aws_api_gateway_rest_api" "signin" {
  name = "AwsSigninWithOIDC"
}

resource "aws_api_gateway_resource" "federation" {
  rest_api_id = "${aws_api_gateway_rest_api.signin.id}"
  parent_id = "${aws_api_gateway_rest_api.signin.root_resource_id}"
  path_part = "federation"
}

resource "aws_api_gateway_method" "get_federation" {
  rest_api_id = "${aws_api_gateway_rest_api.signin.id}"
  resource_id = "${aws_api_gateway_resource.federation.id}"
  http_method = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.Action" = true
    "method.request.querystring.Session" = true
    "method.request.querystring.SessionDuration" = true
  }
}

resource "aws_api_gateway_integration" "get_federation" {
  rest_api_id = "${aws_api_gateway_rest_api.signin.id}"
  resource_id = "${aws_api_gateway_resource.federation.id}"
  http_method = "${aws_api_gateway_method.get_federation.http_method}"
  type = "HTTP"
  integration_http_method = "GET"
  uri = "https://signin.aws.amazon.com/federation"
  request_parameters = {
    "integration.request.querystring.Action" = "method.request.querystring.Action"
    "integration.request.querystring.Session" = "method.request.querystring.Session"
    "integration.request.querystring.SessionDuration" = "method.request.querystring.SessionDuration"
  }
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.signin.id}"
  resource_id = "${aws_api_gateway_resource.federation.id}"
  http_method = "${aws_api_gateway_method.get_federation.http_method}"
  status_code = "200"
  response_models = {
    "text/html" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "get_federation" {
  rest_api_id = "${aws_api_gateway_rest_api.signin.id}"
  resource_id = "${aws_api_gateway_resource.federation.id}"
  http_method = "${aws_api_gateway_method.get_federation.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  response_templates {
    "text/html" = "${file("response.vm")}"
  }
}

resource "aws_api_gateway_deployment" "signin" {
  depends_on = [
    "aws_api_gateway_method.get_federation",
    "aws_api_gateway_method_response.200",
    "aws_api_gateway_integration.get_federation",
    "aws_api_gateway_integration_response.get_federation",
  ]
  rest_api_id = "${aws_api_gateway_rest_api.signin.id}"
  stage_name = "prod"
}

output "origin" {
  value = "https://${aws_s3_bucket.web.bucket}.s3${var.aws_region == "us-east-1" ? "" : "-${var.aws_region}"}.amazonaws.com"
}

output "google" {
  value = {
    dev = "https://${aws_s3_bucket.web.bucket}.s3${var.aws_region == "us-east-1" ? "" : "-${var.aws_region}"}.amazonaws.com/google?role=${aws_iam_role.dev.arn}",
    admin = "https://${aws_s3_bucket.web.bucket}.s3${var.aws_region == "us-east-1" ? "" : "-${var.aws_region}"}.amazonaws.com/google?role=${aws_iam_role.admin.arn}"
  }
}

