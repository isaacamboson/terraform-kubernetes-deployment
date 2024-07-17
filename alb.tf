#creating aws application loadbalancer, target group and lb http listener

resource "aws_lb" "lb" {
  name                             = "${local.ApplicationPrefix}-lb"
  subnets                          = [aws_subnet.pub_subnets[0].id, aws_subnet.pub_subnets[1].id]
  security_groups                  = [aws_security_group.lb-sg.id]
  internal                         = false
  load_balancer_type               = "application"
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
}

#redirecting all incoming traffic from LB to the target group
resource "aws_lb_listener" "clixx-app" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:us-east-1:767398027423:certificate/fc736fd3-2c80-49fd-82e7-f32d4a8128b8"
  # certificate_arn   = aws_acm_certificate.alb_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clixx-app-tg.arn
  }
}

resource "aws_lb_target_group" "clixx-app-tg" {
  name        = "${local.ApplicationPrefix}-app-tg"
  port        = 30000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_main.id

  deregistration_delay = 120

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    interval            = 15
    matcher             = "200" #HTTP status code matcher for healthcheck
    path                = "/"   #Endpoint for ALB healthcheck
    port                = "traffic-port"
  }

  depends_on = [aws_lb.lb]
}

# LB Security Group: Edit to restrict access to the application
resource "aws_security_group" "lb-sg" {
  name        = "${local.ApplicationPrefix}-lb-security-group"
  description = "controls access to the LB"
  vpc_id      = aws_vpc.vpc_main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.ApplicationPrefix}-alb-sg"
  }
}
