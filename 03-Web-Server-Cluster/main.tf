# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Deploy a Cluster of Web Servers
# This template deploys an auto scaling group with web servers farm
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# CONFIGURE AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-west-2"
}

# ------------------------------------------------------------------------------
# DEFINE VARIABLES
# ------------------------------------------------------------------------------

variable "server_port" {
  description = "The TCP port number for web server"
  type = number
  default = 8080
}

variable "asg_name" {
  description = "The Autoscaling Group name"
  type = string
  default = "tf-asg"
}

# ------------------------------------------------------------------------------
# DATA SOURCES
# ------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}


# ------------------------------------------------------------------------------
# DEPLOY AN AUTO SCALING GROUP
# ------------------------------------------------------------------------------

resource "aws_launch_configuration" "launch_configuration" {  
  # Ubuntu Server 18.04LTS
  image_id        = "ami-02701bcdc5509e57b"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.security_group.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, Patrice" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.launch_configuration.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.target_group.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 6

  tag {
    key                 = "Name"
    value               = var.asg_name
    propagate_at_launch = true
  }
}

resource "aws_security_group" "security_group" {
  name = "${var.asg_name}-security-group"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "${var.asg_name}-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb_security_group.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "target_group" {

  name = "${var.asg_name}-target-group"

  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_security_group" "alb_security_group" {
  name = "${var.asg_name}-alb-security-group"

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "alb_dns_name" {
  value       = aws_lb.lb.dns_name
  description = "The domain name of the load balancer"
}