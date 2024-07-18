
variable "AWS_REGION" {
  default     = "us-east-1"
  description = "AWS region where our resources are going to be deployed"
}

variable "availability_zone" {
  default = [
    "us-east-1a",
    "us-east-1b"
  ]
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [
    "10.1.2.0/23", # 510 hosts   - bastion, load balancer
    "10.1.4.0/23"  # 510 hosts   - bastion, load balancer
  ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = [
    "10.1.0.0/24", # 254 hosts   - Application Server
    "10.1.1.0/24", # 254 hosts   - Application Server
    "10.1.8.0/22", # 1022 hosts  - RDS
    "10.1.12.0/22" # 1022 hosts  - RDS
  ]
}

variable "environment" {
  default = "dev"
}

variable "OwnerEmail" {
  default = "isaacamboson@gmail.com"
}

variable "device_names" {
  default = ["/dev/sdb", "/dev/sdc", "/dev/sdd", "/dev/sde", "/dev/sdf"]
}

#controls / conditionals
variable "stack_controls" {
  type = map(string)
  default = {
    ec2_create = "Y"
    # ec2_create_clixx = "Y"
    # ec2_create_blog  = "Y"
    rds_create_clixx = "Y"
    # rds_create_blog  = "Y"
  }
}

#components for EC2 instances
variable "EC2_Components" {
  type = map(string)
  default = {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = "true"
    instance_type         = "t2.large"
  }
}

