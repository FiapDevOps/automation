terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "aws_vpc" "my_vpc" {
  tags = {
    Terraform = "true"
    Environment = "lab"
  }
}

data "aws_security_group" "selected" {
  vpc_id      = data.aws_vpc.my_vpc.id
  tags = {
    Terraform = "true"
    Environment = "lab"
    Tier = "FE"
  }
}

resource "aws_instance" "docker-instance" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3a.medium"
    associate_public_ip_address = true    
    vpc_security_group_ids      = [data.aws_security_group.selected.id]
    subnet_id                   = each.value
  
    tags = {
        Name        = "docker-instance"
        Terraform   = "true"
        Imutable    = "true"
    }
}