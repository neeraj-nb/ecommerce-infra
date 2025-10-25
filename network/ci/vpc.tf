resource "aws_vpc" "ci-server-vpc" {
  cidr_block = var.cidr_block

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "CI-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.ci-server-vpc.id
  cidr_block = var.cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "CI-public-subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.ci-server-vpc.id

  tags = {
    Name = "CI-ig"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ci-server-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "CI-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}