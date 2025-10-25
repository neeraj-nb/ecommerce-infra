output "vpc_id" {
  value = aws_vpc.ci-server-vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet.id
}
