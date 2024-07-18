#-----------------------------------------------------------------------------
## Creates an ASG linked with our main VPC
#-----------------------------------------------------------------------------

resource "aws_autoscaling_group" "k8s_worker_asg" {
  name                      = "${local.ApplicationPrefix}_worker_${var.environment}"
  desired_capacity          = 4
  max_size                  = 8
  min_size                  = 4
  health_check_grace_period = 300
  vpc_zone_identifier       = [aws_subnet.private_subnets[0].id] #, aws_subnet.private_subnets[1].id]
  health_check_type         = "EC2"
  target_group_arns         = [aws_lb_target_group.clixx-app-tg.arn]
  default_cooldown          = 300
  protect_from_scale_in     = true

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.clixx-k8s-worker-LT.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "${local.ApplicationPrefix}_worker_${var.environment}"
    propagate_at_launch = true
  }

  depends_on = [aws_lb.lb, aws_autoscaling_group.k8s_master_asg, aws_launch_template.clixx-k8s-master-LT]
}

#-----------------------------------------------------------------------------
#creating Launch Template for the autoscaling group instances
#-----------------------------------------------------------------------------

resource "aws_launch_template" "clixx-k8s-worker-LT" {
  name                   = "${local.ApplicationPrefix}-worker-LT"
  image_id               = data.aws_ami.k8s_ami.image_id
  instance_type          = var.EC2_Components["instance_type"]
  key_name               = "private-key-kp"
  user_data              = base64encode(data.template_file.k8s-worker-node-bootstrap.rendered)
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  iam_instance_profile {
    name = "stack_ecr_role"
  }

  monitoring {
    enabled = true
  }

  dynamic "block_device_mappings" {
    for_each = var.device_names
    content {
      device_name = block_device_mappings.value

      ebs {
        volume_size = 10
        volume_type = "gp2"
        encrypted   = true
      }
    }
  }

  tags = {
    Name = "${local.ApplicationPrefix}_worker"
  }

  depends_on = [aws_lb.lb, aws_autoscaling_group.k8s_master_asg, aws_launch_template.clixx-k8s-master-LT]
}


