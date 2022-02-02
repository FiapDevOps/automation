# https://www.terraform.io/language/values/outputs

output "vpc_id" {
  value = module.vpc.vpc_id
  description = "The vpc id generated after terraform execution"
}