output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.talend_re.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.talend_re.public_ip
}

output "talend_re_pairing_key" {
  description = "This is the pairing key used for paired remote engine in TMC"
  value       = local.json_data.preAuthorizedKey
}

# output "api_AuthKey" {
#   description = "Talend Authorization key"
#   value       = local.json_data.preAuthorizedKey
# }
