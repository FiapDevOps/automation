# https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/examples/http/main.tf


# Configurando o cloud provider
provider "aws" {
  region = "us-east-1"
}

locals {
  # Ids for multiple sets of EC2 instances, merged together
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}


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

# Exemplo 1: Construindo um security group com base no modulo http-80 para liberar ingresso na porta 80 de qualquer origem
module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "web-server"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.my_vpc.id

  tags = {
    Terraform = "true"
    Environment = "lab"
    Tier = "FE"
  }

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

# Exemplo 2: Construindo um security group com dois tipos de regras:
# 1 Reggra de acesso na mesma porta baseada em três ranges fictios de backends;
# 2 Regra baseada no acesso a porta 3306 com origem no grupo criado anteriomente;
  
module "mysql_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/mysql"

  name        = "computed-mysql-sg"
  description = "Security group with MySQL/Aurora port open for HTTP security group created above (computed)"
  vpc_id      = data.aws_vpc.my_vpc.id

  ingress_cidr_blocks = local.private_subnets

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.web_server_sg.security_group_id
    },
  ]

  number_of_computed_ingress_with_source_security_group_id = 1
}
