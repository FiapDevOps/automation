output "security_group_id" {
  description = "The ID of the security group"
  value       = module.web_server_sg.security_group_id
}