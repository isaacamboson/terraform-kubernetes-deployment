data "aws_ami" "stack_ami" {
  owners = ["self"]
  # owners      = ["767398027423"]
  name_regex  = "^ami-stack*"
  most_recent = true
  filter {
    name   = "name"
    values = ["ami-stack-*"]
  }
}

data "aws_ami" "k8s_ami" {
  owners      = ["767398027423"]
  name_regex  = "^pre-baked-k8s*"
  most_recent = true

  filter {
    name   = "name"
    values = ["pre-baked-k8s*"]
  }
}

data "aws_secretsmanager_secret_version" "creds" {
  # fill in the name you gave the secret
  secret_id = "creds"
}

data "aws_route53_zone" "stack_isaac_zone" {
  name         = "stack-isaac.com." # Notice the dot!!!
  private_zone = false
}