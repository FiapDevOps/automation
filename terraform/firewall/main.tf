# https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/examples/http/main.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group


# Configurando o cloud provider
provider "aws" {
  region = "us-east-1"
}

locals {
  # Ids for multiple sets of EC2 instances, merged together
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


data "aws_vpc" "main" {
  tags = {
    terraform = "true"
    env       = "lab"
  }
}

data "aws_vpc" "def_vpc" {
  default = true
}

data "aws_security_group" "cloud9_sg" {
  vpc_id = data.aws_vpc.def_vpc.id

  filter {
    name   = "group-name"
    values = ["*cloud9*"]
  }
}

# Exemplo 1: Construindo um security group para liberar ingresso na porta 80 de qualquer origem:

resource "aws_security_group" "web_server_sg" {

  name        = "allow_web_server_access"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description      = "Allow HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web_server_access"
    terraform = "true"
    env = "lab"
    tier = "public"
  }
}

# Exemplo 2: Construindo um security group usando um modulo externo e dois tipos de regras:
# 1 Regra de acesso na mesma porta baseada em dois ranges fictios de backends;
# 2 Regra baseada no acesso a porta 3306 com origem no grupo criado anteriomente;
  
module "mysql_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/mysql"

  name        = "allow_access_to_mysql_backend"
  description = "Security group with MySQL/Aurora port open for HTTP security group created above (computed)"
  vpc_id      = data.aws_vpc.main.id

  ingress_cidr_blocks = local.private_subnets

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = aws_security_group.web_server_sg.id
    },
  ]

  number_of_computed_ingress_with_source_security_group_id = 1
}


# Exemplo 3: Configurando acesso remoto via SSH entre dois groupos:
# Para liberar execute: sed -i '105,142s/^#//' main.tf

#resource "aws_security_group" "allow_access_from_cloud9_sg" {

#  name        = "allow_access_from_cloud9_sg"
#  description = "Allow Cloud9 Security Group to access new Security Group Instances"
#  vpc_id      = data.aws_vpc.main.id
  
#  ingress {
#    description      = "Allow SSH"
#    from_port        = 22
#    to_port          = 22
#    protocol         = "tcp"
#    security_groups = [data.aws_security_group.cloud9_sg.id]
#  }

#  ingress {
#    description      = "Allow ICMP"
#    from_port = -1
#    to_port = -1
#    protocol = "icmp"
#    security_groups = [data.aws_security_group.cloud9_sg.id]
#  }

#  egress {
#    from_port        = 0
#    to_port          = 0
#    protocol         = "-1"
#    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
#  }
#
#  tags = { 
#    Name = "allow_access_from_cloud9_sg"
#    terraform = "true"
#    env       = "lab"
#    tier      = "private"
#  }
#}
