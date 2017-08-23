provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_iam_openid_connect_provider" "google" {
  url = "https://accounts.google.com"
  thumbprint_list = "${var.thumbprint["google"]}"
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

