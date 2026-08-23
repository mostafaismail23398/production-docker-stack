terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# Default VPC
# -------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------
# Latest Ubuntu AMI
# -------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------
# Security Group
# -------------------------

resource "aws_security_group" "app" {
  name        = "production-docker-stack-sg"
  description = "Security group for production Docker stack"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS for future use
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "production-docker-stack-sg"
  }
}

# -------------------------
# EC2 Instance
# -------------------------

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  key_name = var.key_name

  user_data = <<-EOF
              #!/bin/bash

              apt-get update -y

              apt-get install -y \
                docker.io \
                docker-compose-v2 \
                git

              systemctl enable docker
              systemctl start docker

              usermod -aG docker ubuntu

              mkdir -p /opt/production-docker-stack
              chown -R ubuntu:ubuntu /opt/production-docker-stack
              EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "production-docker-stack"
  }
}