#-------------------------------------------------------------------------
#creating security group for bastion - this allows traffic from 0.0.0.0/0
#-------------------------------------------------------------------------

resource "aws_security_group" "bastion-sg" {
  vpc_id      = aws_vpc.vpc_main.id
  name        = "bastion-sg"
  description = "Security Group for bastion - this allows traffic from 0.0.0.0/0"
}

#declaring "ingress" security group rules for ssh
resource "aws_security_group_rule" "ingress_ssh_bastion_sg" {
  security_group_id = aws_security_group.bastion-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

#declaring "ingress" security group rules for http
resource "aws_security_group_rule" "ingress_http_bastion_sg" {
  security_group_id = aws_security_group.bastion-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

#declaring "ingress" security group rules for ssh
resource "aws_security_group_rule" "ingress_https_bastion_sg" {
  security_group_id = aws_security_group.bastion-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

#declaring "ingress" security group rules for MySQL
resource "aws_security_group_rule" "ingress_mysql_bastion_sg" {
  security_group_id = aws_security_group.bastion-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = ["0.0.0.0/0"]
}

#declaring "ingress" security group rules for ICMP
resource "aws_security_group_rule" "ingress_icmp_bastion_sg" {
  security_group_id = aws_security_group.bastion-sg.id
  type              = "ingress"
  protocol          = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_blocks       = ["0.0.0.0/0"]
}

#declaring "egress" security group rules for ssh
resource "aws_security_group_rule" "egress_allow_all_bastion_sg" {
  security_group_id = aws_security_group.bastion-sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}