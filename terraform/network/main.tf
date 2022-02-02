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
  region = "us-west-2"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    terraform = "true"
    environment = "lab"
  }
}

####################################################################################
# Peering

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_tables
# https://github.com/hashicorp/terraform-provider-aws/issues/373

# Recuperando dados da VPC Default
data "aws_vpc" "default" {
  default = true
}

# Recuperando dados da Default Routing Table
data "aws_route_table" "selected" {
  vpc_id  = data.aws_vpc.default.id
}

# Recuperando dados das Tabelas de roteamento geradas com a nova VPC e suas respectivas subnets
data "aws_route_tables" "rts" {
  tags = {
    terraform = "true"
    environment = "lab"
  }
}


# Criando o peering entre as VPCS:
resource "aws_vpc_peering_connection" "main" {
  peer_vpc_id   = module.vpc.vpc_id
  vpc_id        = data.aws_vpc.default.id
  auto_accept   = true

  tags = {
    Name = "VPC Peering between main and default vpcs"
  }
}

resource "aws_route" "route_to_main_vpc" {
  route_table_id            = data.aws_route_table.selected.id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

resource "aws_route" "route_to_default_vpc" {

  count                     = length(data.aws_route_tables.rts.ids)
  route_table_id            = tolist(data.aws_route_tables.rts.ids)[count.index]
  destination_cidr_block    = "172.31.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}