# https://www.terraform.io/language/settings/backends/s3
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

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

data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "group-name"
    values = ["default"]
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

# Nunca tente isso em prod. utilize um circuito de rede fechado como um peering ao inves de expor a porta 10050 para internet

resource "aws_security_group_rule" "open-port-10050" {
  type              = "ingress"
  from_port         = 10050
  to_port           = 10050
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default.id
}

resource "aws_instance" "monitored_app" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3a.medium"
    associate_public_ip_address = true    
    user_data                   = "${file("templates/mediawiki.yaml")}"
    vpc_security_group_ids      = [data.aws_security_group.default.id]
    key_name                    = "id_lab"
    count                       = 1

    tags = {
        terraform   = "true"
        env         = "lab"
        tier        = "defaut"
        purpose     = "mediawiki"
        
    }
}