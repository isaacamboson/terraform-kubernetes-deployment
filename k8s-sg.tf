# this security group for autoscaling instances - Traffic to the kubernetes cluster should only come from the LB
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-tasks-security-group"
  description = "allow inbound access from the LB only for EC2 in cluster"
  vpc_id      = aws_vpc.vpc_main.id

  #dynamic block for allowing ingress traffic for allowing ports 80, 443, 8080, 22
  dynamic "ingress" {
    for_each = local.inbound_ports
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.lb-sg.id, aws_security_group.bastion-sg.id]
    }
  }

  ingress {
    description     = "NodePort Services"
    protocol        = "tcp"
    from_port       = 30000
    to_port         = 32767
    security_groups = [aws_security_group.lb-sg.id, aws_security_group.bastion-sg.id]
  }

  ingress {
    description     = "kube-apiserver, etcd"
    protocol        = "tcp"
    from_port       = 2379
    to_port         = 2380
    security_groups = [aws_security_group.lb-sg.id, aws_security_group.bastion-sg.id]
  }

  ingress {
    description     = "kubelet API"
    protocol        = "tcp"
    from_port       = 10250
    to_port         = 10259
    security_groups = [aws_security_group.lb-sg.id, aws_security_group.bastion-sg.id]
  }

  ingress {
    description     = "API server port"
    protocol        = "tcp"
    from_port       = 6443
    to_port         = 6443
    security_groups = [aws_security_group.lb-sg.id, aws_security_group.bastion-sg.id]
    self            = true
  }

  ingress {
    description = "weave-net"
    protocol    = "tcp"
    from_port   = 6783
    to_port     = 6783
    cidr_blocks = ["10.1.0.0/16"]     #vpc cidr - to allow connection between nodes
  }

  ingress {
    description     = "Allow icmp ingress traffic from bastion host"
    protocol        = "icmp"
    from_port       = -1
    to_port         = -1
    security_groups = [aws_security_group.lb-sg.id, aws_security_group.bastion-sg.id]
  }

  egress {
    description = "Allow all egress traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

