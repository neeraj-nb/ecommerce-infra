resource "aws_route53_zone" "internal" {
  name = "internal.neerajbabu.tech"
  vpc {
    vpc_id = aws_vpc.k8s-vpc.id
  }
}

resource "aws_ec2_client_vpn_endpoint" "internal_vpn" {
  description = "internal-vpn"
  server_certificate_arn = "arn:aws:acm:ap-south-1:204649420486:certificate/109d9b40-69eb-4cc0-836f-9e353b9db91f"
  client_cidr_block = "10.10.0.0/24"

  authentication_options {
    type = "certificate-authentication"
    root_certificate_chain_arn = "arn:aws:acm:ap-south-1:204649420486:certificate/080f2281-2f19-4e15-a753-ac273dbfc069"
  }
  connection_log_options {
    enabled = false
  }
  split_tunnel = true
  dns_servers = ["10.100.0.10", "8.8.8.8"]
  transport_protocol = "udp"
  vpn_port = 443

  tags = {
    name = "eks-client-vpn"
  }
}

resource "aws_ec2_client_vpn_network_association" "internal" {
  count = 2
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.internal_vpn.id
  subnet_id = local.private_subnets[count.index]
}

resource "aws_ec2_client_vpn_authorization_rule" "eks_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.internal_vpn.id
  target_network_cidr = var.vpc_cidr
  authorize_all_groups = true
}

resource "aws_ec2_client_vpn_route" "eks_cluster" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.internal_vpn.id
  destination_cidr_block = var.vpc_cidr
  target_vpc_subnet_id = local.private_subnets[0]
}