# https://www.terraform.io/language/values/outputs

output "app_private_addr" {
  value = aws_instance.monitored_app[0].private_ip
  description = "The mediawiki private ip address"
}

output "app_public_addr" {
  value = aws_instance.monitored_app[0].public_ip
  description = "The mediawiki public ip address"
}