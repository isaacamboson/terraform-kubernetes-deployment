#creating a VPC
resource "aws_vpc" "vpc_main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${local.ApplicationPrefix}_VPC"
  }
}

#creating public subnets
resource "aws_subnet" "pub_subnets" {
  count             = length(var.availability_zone)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zone[count.index]

  tags = {
    Name = "${local.PublicPrefix}_Subnet_${count.index}"
  }
}

#creating private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zone, count.index)

  tags = {
    Name = "${local.PrivatePrefix}_Subnet_${count.index}"
  }
}

#creating IGW for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_main.id

  tags = {
    Name = "${local.PrivatePrefix}_VPC_IGW"
  }
}

#associating the main vpc route table with the IGW
resource "aws_route" "pub_custom_route_table" {
  route_table_id         = aws_vpc.vpc_main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#creating EIPs for NAT Gateways
resource "aws_eip" "eip_aws_nat_gtwy" {
  count      = length(var.availability_zone)
  depends_on = [aws_internet_gateway.igw]
}

# Associating EIPs with NAT Gateways
resource "aws_nat_gateway" "nat_gateway_pub" {
  count         = length(var.availability_zone)
  allocation_id = element(aws_eip.eip_aws_nat_gtwy.*.id, count.index)
  subnet_id     = element(aws_subnet.pub_subnets.*.id, count.index)
  depends_on    = [aws_eip.eip_aws_nat_gtwy, aws_subnet.pub_subnets]

  tags = {
    Name = "NAT_Gateway_${count.index}"
  }
}

#creating custom route tables for the private subnets
resource "aws_route_table" "private_custom_route_table" {
  count  = length(var.availability_zone)
  vpc_id = aws_vpc.vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_nat_gateway.nat_gateway_pub.*.id, count.index)
  }

  tags = {
    Name = "${local.PrivatePrefix}_Route_Table_${count.index}"
  }
}

# associating route tables with the private subnets
resource "aws_route_table_association" "rt_association_private_subnets" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_custom_route_table.*.id, count.index)
}

