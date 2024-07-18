#----------------------------------------------------------------------------
#creating EIP for AWS instance - bastion in AZ-A and associating IP address
#----------------------------------------------------------------------------

# Bastion AWS instance in AZ A and B
resource "aws_instance" "bastion" {
  count                       = var.stack_controls["ec2_create"] == "Y" ? 1 : 0
  ami                         = data.aws_ami.stack_ami.id
  instance_type               = var.EC2_Components["instance_type"]
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  key_name                    = "bastion_kp"
  subnet_id                   = aws_subnet.pub_subnets[0].id
  associate_public_ip_address = "true"
  iam_instance_profile        = "ec2_to_s3_admin"
  user_data                   = data.template_file.bastion_s3_cp_bootstrap.rendered

  tags = {
    Name        = "Bastion_${count.index}"
    Environment = var.environment
    OwnerEmail  = var.OwnerEmail
  }
}
