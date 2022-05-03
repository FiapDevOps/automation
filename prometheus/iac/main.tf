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
  backend "s3" {
    bucket = "mybucket"
    key    = "monitoring"
    region = "us-east-1"
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

# Firewall rules

resource "aws_security_group_rule" "open-port-9090" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default.id
}

resource "aws_security_group_rule" "open-port-8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default.id
}

resource "aws_security_group_rule" "open-port-9100" {
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default.id
}


resource "aws_instance" "monitoring_app" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3a.medium"
    associate_public_ip_address = true    
    user_data                   = "${file("templates/prometheus.yaml")}"
    vpc_security_group_ids      = [data.aws_security_group.default.id]
    key_name                    = "id_lab"

    tags = {
        terraform   = "true"
        env         = "lab"
        tier        = "defaut"
    }
}

resource "aws_instance" "single_app" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3a.medium"
    associate_public_ip_address = true    
    user_data                   = "${file("templates/mediawiki.yaml")}"
    vpc_security_group_ids      = [data.aws_security_group.default.id]
    key_name                    = "id_lab"
    count                       = 0

    tags = {
        terraform = "true"
        env       = "lab"
        tier      = "defaut"
    }
}