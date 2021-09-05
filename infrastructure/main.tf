variable "profile" { type = string }

# Project name
variable "project" {
  default = "notejam"
}

# Project region
variable "region" {}
data "aws_caller_identity" "current" {}

# Account id
locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

# AWS provider
provider "aws" {
  profile  = var.profile
  region   = var.region
}
