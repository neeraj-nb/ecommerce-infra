output "vpn_endpoint" {
  value = aws_ec2_client_vpn_endpoint.internal_vpn.id
  description = "Client VPN endpoint ID"
}