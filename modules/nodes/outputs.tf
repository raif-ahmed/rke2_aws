output "ip_addresses" {
  description = "List of primary private IP addresses for master nodes"
  value       = aws_instance.ec2[*].private_ip
}

