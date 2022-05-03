# Modelos de referência: 
# Uso da AWS como Cloud Provider: "https://registry.terraform.io/providers/hashicorp/aws/latest/docs"
# Modulo de configuração de Rede: "https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest"

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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    terraform = "true"
    env = "lab"
  }
}

### ---- Peering ----

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_tables
# https://github.com/hashicorp/terraform-provider-aws/issues/373

# ---- Remova os comentarios do bloco abaixo para executar respectivamente as tarefas:
# ---- Data source para recuperar dados da VPC Default;
# ---- Data source para recuperar dados da Default Routing Table;
# ---- Data source para recuperar dados das Tabelas de roteamento;
# ---- Criar o peering entre as VPCS;
# ---- Criar uma rota entre a VPC Default e o range 10.0.0.0/16 (Usado no Peering)
# ---- Criar uma rota entre a VPC de Peering e o range 172.31.0.0/16 da VPC Default

# Para liberar execute: sed -i '54,91s/^#//' main.tf

#data "aws_vpc" "default" {
#  default = true
#}

#data "aws_route_table" "selected" {
#  vpc_id  = data.aws_vpc.default.id
#}

#data "aws_route_tables" "rts" {
#  tags = {
#    terraform = "true"
#    env = "lab"
#  }
#}

#resource "aws_vpc_peering_connection" "main" {
#  peer_vpc_id   = module.vpc.vpc_id
#  vpc_id        = data.aws_vpc.default.id
#  auto_accept   = true

#  tags = {
#    Name = "VPC Peering between main and default vpcs"
#  }
#}

#resource "aws_route" "route_to_main_vpc" {
#  route_table_id            = data.aws_route_table.selected.id
#  destination_cidr_block    = "10.0.0.0/16"
#  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
#}

#resource "aws_route" "route_to_default_vpc" {

#  count                     = length(data.aws_route_tables.rts.ids)
#  route_table_id            = tolist(data.aws_route_tables.rts.ids)[count.index]
#  destination_cidr_block    = "172.31.0.0/16"
#  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
#}
