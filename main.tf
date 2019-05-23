provider "aws" {
  region = "${var.aws_region}"
}

data "external" "google" {
  program = ["sh", "obtain_oidc_thumbprint.sh"]
  query = {
    url = "${var.url["google"]}"
  }
}

resource "aws_iam_openid_connect_provider" "google" {
  url = "${var.url["google"]}"
  thumbprint_list = ["${split(" ", data.external.google.result["thumbprints"])}"]
  client_id_list = ["${var.client_id["google"]}"]
}

data "template_file" "origin" {
  template = "https://$${bucket}.s3$${region}.amazonaws.com"
  vars {
    bucket = "${var.s3_bucket}"
    region = "${var.aws_region == "us-east-1" ? "" : "-${var.aws_region}"}"
  }
}

output "origin" {
  value = "${data.template_file.origin.rendered}"
}

