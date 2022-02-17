terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configurando o cloud provider
provider "aws" {
  region = "us-east-1"
}

data "aws_security_groups" "selected" {

  filter {
    name   = "group-name"
    values = ["*default*"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web_app" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t2.micro"
    associate_public_ip_address = true    
    user_data                   = "${file("templates/nginx.yaml")}"
    vpc_security_group_ids      = data.aws_security_groups.selected.ids
    key_name                    = "id_lab"
    count                       = 0

    tags = {
        terraform   = "true"
        environment = "lab"
        tier        = "defaut"
    }
}

resource "aws_instance" "prometheus" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3a.medium"
    associate_public_ip_address = true    
    user_data                   = "${file("templates/prometheus.yaml")}"
    vpc_security_group_ids      = data.aws_security_groups.selected.ids
    key_name                    = "id_lab"
    count                       = 1
      
    tags = {
        terraform   = "true"
        environment = "lab"
        tier        = "defaut"
    }
}