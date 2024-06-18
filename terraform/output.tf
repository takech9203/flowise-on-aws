# Output Configuration
output "external_url" {
  description = "The url of Flowise application"
  value       = "http://${aws_lb.public.dns_name}"
}