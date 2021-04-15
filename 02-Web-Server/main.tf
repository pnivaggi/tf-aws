# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A SINGLE EC2 INSTANCE
# This template runs a simple "Hello, World" web server on a single EC2 Instance
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
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

variable "ec2_instance_name" {
  description = "The AWS EC2 instance name"
  type = string
  default = "tf-web-server"
}

# ------------------------------------------------------------------------------
# DEPLOY A SINGLE EC2 INSTANCE
# ------------------------------------------------------------------------------

resource "aws_instance" "instance" {
  # Amazon Linux
  # ami           = "ami-05b622b5fa0269787"
  
  # Ubuntu Server 18.04LTS
  ami             = "ami-02701bcdc5509e57b"

  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_group.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, Patrice" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  tags = {
    Name = var.ec2_instance_name
  }
}

resource "aws_security_group" "security_group" {
  name = "${var.ec2_instance_name}-security-group"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {  
  value       = aws_instance.instance.public_ip  
  description = "The public IP address of the web server"
}