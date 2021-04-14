# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A SINGLE EC2 INSTANCE
# This template deploys a single EC2 Instance
# export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-west-2"
}

# ------------------------------------------------------------------------------
# DEPLOY A SINGLE EC2 INSTANCE
# ------------------------------------------------------------------------------

resource "aws_instance" "example" {
  # Amazon Linux 2
  ami           = "ami-05b622b5fa0269787"
  
  # Ubuntu Server 18.04LTS
  # ami             = "ami-02701bcdc5509e57b"

  instance_type = "t2.micro"

  tags = {
    Name = "terraform-example"
  }
}
