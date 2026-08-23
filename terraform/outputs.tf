output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.app.public_ip
}

output "public_dns" {
  description = "EC2 public DNS"
  value       = aws_instance.app.public_dns
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_instance.app.public_ip}"
}