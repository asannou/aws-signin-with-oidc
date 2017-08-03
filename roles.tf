data "template_file" "dev" {
  template = "${file("role.json")}"
  vars {
    google_federated = "${aws_iam_openid_connect_provider.google.arn}"
    google_aud = "${var.client_id["google"]}"
    google_email = "${jsonencode(var.email["dev"])}"
  }
}

resource "aws_iam_role" "dev" {
  name = "Dev"
  path = "/"
  assume_role_policy = "${data.template_file.dev.rendered}"
}

resource "aws_iam_role_policy_attachment" "dev" {
  role = "${aws_iam_role.dev.name}"
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "template_file" "admin" {
  template = "${file("role.json")}"
  vars {
    google_federated = "${aws_iam_openid_connect_provider.google.arn}"
    google_aud = "${var.client_id["google"]}"
    google_email = "${jsonencode(var.email["admin"])}"
  }
}

resource "aws_iam_role" "admin" {
  name = "Admin"
  path = "/"
  assume_role_policy = "${data.template_file.admin.rendered}"
}

resource "aws_iam_role_policy_attachment" "admin" {
  role = "${aws_iam_role.admin.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

