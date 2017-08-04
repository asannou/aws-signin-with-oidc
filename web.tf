resource "aws_s3_bucket" "web" {
  bucket = "${var.s3_bucket}"
}

resource "aws_s3_bucket_object" "index_html" {
  bucket = "${aws_s3_bucket.web.bucket}"
  key = "index"
  source = "index.html"
  content_type = "text/html"
  acl = "public-read"
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

data "template_file" "response_vm" {
  template = "${file("response.vm")}"
  vars {
    issuer = "${data.template_file.origin.rendered}/index"
  }
}

resource "aws_api_gateway_integration_response" "get_federation" {
  rest_api_id = "${aws_api_gateway_rest_api.signin.id}"
  resource_id = "${aws_api_gateway_resource.federation.id}"
  http_method = "${aws_api_gateway_method.get_federation.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  response_templates {
    "text/html" = "${data.template_file.response_vm.rendered}"
  }
}

resource "aws_api_gateway_deployment" "signin" {
  depends_on = [
    "aws_api_gateway_resource.federation",
    "aws_api_gateway_method.get_federation",
    "aws_api_gateway_method_response.200",
    "aws_api_gateway_integration.get_federation",
    "aws_api_gateway_integration_response.get_federation",
  ]
  rest_api_id = "${aws_api_gateway_rest_api.signin.id}"
  stage_name = "prod"
}

