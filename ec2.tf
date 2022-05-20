# security group for ec2
resource "aws_security_group" "ec2_sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "Allow access to web app"
  name = replace(upper(join("_", [
    var.module_spec["${var.environment}"].env_prefix,
    var.module_spec["${var.environment}"].module_name,
    "EC2"
  ])), "-", "_")
  tags = merge(
    tomap(
      {
        "Name" = replace(upper(
          join("_",
            [
              var.module_spec["${var.environment}"].env_prefix,
              var.module_spec["${var.environment}"].module_name,
              "EC2"
            ]
          )
        ), "-", "_")
      }
    ),
    local.additional_tags
  )
}

# alb security group rule 1
resource "aws_security_group_rule" "ec2_rule1" {
  type                     = "ingress"
  description              = "Allow access from alb"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_sg.id
  security_group_id        = aws_security_group.ec2_sg.id
}

# alb security group rule 2
resource "aws_security_group_rule" "ec2_rule2" {
  type                     = "egress"
  description              = "Allow RDS access"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_sg.id
  security_group_id        = aws_security_group.ec2_sg.id
}

# alb security group rule 3
resource "aws_security_group_rule" "ec2_rule3" {
  type                     = "egress"
  description              = "For yum updates"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.ec2_sg.id
}

# Creating Key Pair For EC2
resource "aws_key_pair" "sbwebapp" {
  key_name   = "sbwebapp-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDy6LtTqZNYFgQ1xoqVFBj0fl+rSA4LWdK0fRH6RpWOz95eWyDsFr12PXFyGUasfqfxFEKBNwQxoe3DDKCWihAphnNaS8ORneDMZd5fq6GMzW67Ppwzs/BSZtOWq3c/p/7RwbS/nq7s2X+x544plZnx0bWHk7zcwO7x/g6y8AGuj3XdUU1DoTMnoVJ4fFWuKowTRvRxOqcPuu/plNKl7rfCwpEUjJD1uKRipFRIaGBy6mid7VW0ZFhICdImV+4Q9UQnZHevWoKrBAVzYijaOmOUcKgszWs0aoZk4vgURZI5+ExGMLBVwwCCiFc57GWhY0byhXjr9/piP2ejwGdxgZ5R sbwebapp-key"
}

# Create EC2 instance for WEb APP
resource "aws_instance" "webapp" {
  for_each = aws_subnet.db_subnets
  ami                    = var.ec2_data.ami
  instance_type          = var.ec2_data.instance_type
  key_name               = aws_key_pair.sbwebapp.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = each.value.id
  # iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    volume_size           = var.ec2_data["root_volume"].volume1.size
    volume_type           = var.ec2_data["root_volume"].volume1.type
    delete_on_termination = true
    kms_key_id            = aws_kms_key.sbkms.arn
    encrypted             = true
  }
  volume_tags = merge(
    tomap(
      {
        "Name" = replace(upper(
          join("_",
            [
              var.module_spec["${var.environment}"].env_prefix,
              var.module_spec["${var.environment}"].module_name,
              "EC2"
            ]
          )
        ), "-", "_")
      }
    ),
    local.additional_tags
  )
  user_data = <<EOF
  #!/bin/bash

  # get admin privileges
  sudo su

  # install httpd (Linux 2 version)
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  echo "Hello World from $(hostname -f)" > /var/www/html/index.html
  
  EOF

  tags = merge(
    tomap(
      {
        "Name" = replace(upper(
          join("_",
            [
              var.module_spec["${var.environment}"].env_prefix,
              var.module_spec["${var.environment}"].module_name,
              "EC2"
            ]
          )
        ), "-", "_")
      }
    ),
    local.additional_tags
  )
}


resource "aws_lb_listener_rule" "webapp" {
  listener_arn = aws_lb_listener.lb_pub_https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# target group
resource "aws_lb_target_group" "webapp" {
  name = replace(upper(
    join("-", [
      var.module_spec["${var.environment}"].env_prefix,
      var.module_spec["${var.environment}"].module_name,
      "EC2"
    ])
  ), "_", "-")
  port                 = var.ec2_data.port
  deregistration_delay = 60
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.vpc.id
  health_check {
    path     = "/var/www/html/index.html"
    interval = 30
  }
  lifecycle {
    ignore_changes = [health_check]
  }
  tags = merge(
    tomap(
      {
        "Name" = replace(upper(
          join("_",
            [
              var.module_spec["${var.environment}"].env_prefix,
              var.module_spec["${var.environment}"].module_name,
              "EC2"
            ]
          )
        ), "-", "_")
      }
    ),
    local.additional_tags
  )
}

resource "aws_lb_target_group_attachment" "webapp" {
  for_each         = aws_instance.webapp
  target_group_arn = aws_lb_target_group.webapp.arn
  target_id        = each.value.id
  port             = var.ec2_data.port
}