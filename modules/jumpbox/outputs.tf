output "public_ip" {
  description = "Public IP address of the jumpbox EC2 instance"
  value       = aws_instance.jumpbox.public_ip
}

output "public_dns" {
  description = "Public DNS name of the jumpbox EC2 instance"
  value       = aws_instance.jumpbox.public_dns
}

output "private_ip" {
  description = "Private IP address of the jumpbox EC2 instance"
  value       = aws_instance.jumpbox.private_ip
}