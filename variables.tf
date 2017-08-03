variable "aws_region" {
  type = "string"
}

variable "s3_bucket" {
  type = "string"
}

variable "client_id" {
  type = "map"
}

variable "thumbprint" {
  default = {
    google = ["7359755c6df9a0abc3060bce369564c8ec4542a3"]
  }
}

variable "email" {
  type = "map"
}

