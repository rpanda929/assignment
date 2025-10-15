output "public_ip" {
  description = "Public IPv4 of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "http_url" {
  description = "Convenience URL to open in the browser"
  value       = "http://${aws_instance.web.public_ip}"
}

output "s3_object_url" {
  description = "S3 path where index.html was uploaded"
  value       = "s3://${var.s3_bucket}/terraform/${local.resource_name}/index.html"
}

