terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "tls_private_key" "ec2_key8" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key8" {
  key_name   = "ec2_key8"
  public_key = tls_private_key.ec2_key8.public_key_openssh
}

resource "local_file" "private_key" {
  filename        = "${path.module}/ec2-key.pem"
  content         = tls_private_key.ec2_key8.private_key_pem
  file_permission = "0400"
}
resource "aws_security_group" "web_sg10" {
  name = "web_sg10"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg10.id]
  key_name = aws_key_pair.ec2_key8.key_name

  user_data = file("${path.module}/script.sh")

  tags = { 
    Name = "devops-web"
  }
}