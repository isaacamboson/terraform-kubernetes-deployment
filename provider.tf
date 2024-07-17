provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY

  #assuming the engineer role
  assume_role {
    role_arn = "arn:aws:iam::767398027423:role/Engineer"
  }
}