variable "aws_region" {
  type = "string"
}

variable "s3_bucket" {
  type = "string"
}

variable "url" {
  default = {
    google = "https://accounts.google.com"
  }
}

variable "client_id" {
  type = "map"
}

variable "email" {
  type = "map"
}

variable "lambda_schedule_expression" {
  default = "rate(1 hour)"
}

