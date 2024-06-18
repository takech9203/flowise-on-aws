# Output Configuration
output "external_url" {
  description = "The url of Flowise application"
  value       = "https://${aws_route53_record.flowise.fqdn}"
}