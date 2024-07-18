provider "aws" {
  region = var.AWS_REGION

  #assuming the engineer role
  assume_role {
    role_arn = "arn:aws:iam::767398027423:role/Engineer"
  }
}