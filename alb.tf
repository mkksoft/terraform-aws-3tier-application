# security group for load balancer
resource "aws_security_group" "lb_sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "Allow TLS inbound traffic"
  name = replace(upper(join("_", [
    var.module_spec["${var.environment}"].env_prefix,
    var.module_spec["${var.environment}"].module_name,
    "ALB"
  ])), "-", "_")
  tags = merge(
    tomap(
      {
        "Name" = replace(upper(
          join("_",
            [
              var.module_spec["${var.environment}"].env_prefix,
              var.module_spec["${var.environment}"].module_name,
              "ALB"
            ]
          )
        ), "-", "_")
      }
    ),
    local.additional_tags
  )
}

# alb security group rule 1
resource "aws_security_group_rule" "rule1" {
  type              = "ingress"
  description       = "Allow all traffic"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

# alb security group rule 2
resource "aws_security_group_rule" "rule2" {
  type              = "ingress"
  description       = "Allow all traffic"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

# alb security group rule 3
resource "aws_security_group_rule" "rule3" {
  type              = "egress"
  description       = "Allow access to ec2"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
  security_group_id = aws_security_group.lb_sg.id
}

# application load balancer (PUBLIC)
resource "aws_lb" "lb_pub" {
  name = lower(replace(
    join("-", [
      var.module_spec["${var.environment}"].env_prefix,
      var.module_spec["${var.environment}"].module_name,
      "pub"
      ]
    ),
  "_", "-"))
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_subnets["pub2a"].id, aws_subnet.public_subnets["pub2b"].id, aws_subnet.public_subnets["pub2c"].id]
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = merge(
    tomap(
      {
        "Name" = replace(upper(
          join("_",
            [
              var.module_spec["${var.environment}"].env_prefix,
              var.module_spec["${var.environment}"].module_name,
              "PUB",
              "ALB"
            ]
          )
        ), "-", "_")
      }
    ),
    local.additional_tags
  )
}

# lb_pub listners
resource "aws_lb_listener" "lb_pub_http" {
  load_balancer_arn = aws_lb.lb_pub.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Creating a test certificate
resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "example" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.example.private_key_pem
  certificate_body = tls_self_signed_cert.example.cert_pem
}

# lb_pub https listener rule for webapp
resource "aws_lb_listener" "lb_pub_https" {
  load_balancer_arn = aws_lb.lb_pub.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

# # lb_pub listener rule for app2

# resource "aws_lb_listener_rule" "app2" {
# listener_arn = aws_lb_listener.lb_pub.arn
# priority     = 100

# action {
# type             = "forward"
# target_group_arn = aws_lb_target_group.tg["tg2"].arn
# }

# condition {
# http_header {
#   http_header_name = "tenantId"
#   values           = var.http_header_names_app2
# }
# }
# }
