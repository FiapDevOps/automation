# https://www.terraform.io/language/values/outputs

output "prometheus_public_ip" {
  value = aws_instance.monitoring_app.public_ip
  description = "The prometheus public ip address"
}

output "prometheus_private_ip" {
  value = aws_instance.monitoring_app.private_ip
  description = "The prometheus private ip address"
}

#output "single_app_addr" {
#  value = aws_instance.single_app[0].public_ip
#  description = "The mediawiki public ip address"
#}