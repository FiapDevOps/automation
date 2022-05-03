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

data "aws_vpc" "main" {
  tags = {
    terraform = "true"
    env       = "lab"
  }
}

data "aws_security_groups" "selected" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    terraform = "true"
    env = "lab"
  }
}

data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.main.id

  filter {
    name   = "tag:Name"
    values = ["*public*"] # insert values here
  }

  tags = {
    terraform = "true"
    env = "lab"
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
  for_each                      = data.aws_subnet_ids.selected.ids
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3a.medium"
    associate_public_ip_address = true    
    user_data                   = "${file("templates/nginx.yaml")}"
#   user_data                   = "${file("templates/mediawiki.yaml")}"
    vpc_security_group_ids      = tolist(data.aws_security_groups.selected.ids)
    key_name                    = "id_lab"

    subnet_id                   = each.value
  
    tags = {
        terraform = "true"
        env       = "lab"
        tier      = "public"
    }
}
