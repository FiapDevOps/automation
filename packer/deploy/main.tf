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
    terraform = "true"
    env       = "lab"
  }
}

data "aws_security_group" "selected" {
  vpc_id      = data.aws_vpc.my_vpc.id
  tags = {
    terraform = "true"
    env       = "lab"
    tier      = "FE"
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
        terraform   = "true"
        imutable    = "true"
        env         = "lab"
    }
}