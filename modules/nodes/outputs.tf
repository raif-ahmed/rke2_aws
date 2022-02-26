output "ip_addresses" {
  value = aws_network_interface.ec2.*.private_ips
}

