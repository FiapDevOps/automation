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

data "aws_vpc" "my_vpc" {
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

data "aws_security_group" "selected" {
  vpc_id      = data.aws_vpc.my_vpc.id
  tags = {
    Terraform = "true"
    Environment = "dev"
    Tier = "FE"
  }
}

data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.my_vpc.id

  filter {
    name   = "tag:Name"
    values = ["*public*"] # insert values here
  }

  tags = {
    Terraform = "true"
    Environment = "dev"
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
    instance_type               = "t2.medium"
    associate_public_ip_address = true    
    user_data                   = "${file("templates/mediawiki.yaml")}"
    vpc_security_group_ids      = [data.aws_security_group.selected.id]
    subnet_id                   = each.value
  
    tags = {
        Name        = "mediawiki"
        Terraform   = "true"
        Environment = "dev"
        Tier        = "public"
    }
}
