output "rancher_server_url" {
  description = "The URL of the Rancher server."
  value       = module.vpc.external_ingress_dns_name != null && module.vpc.external_ingress_dns_name != "" ? "https://${module.vpc.external_ingress_dns_name}" : null
}

output "jumpbox_public_ip" {
  description = "Public IP address of the Jumpbox"
  value       = module.jumpbox.public_ip
}