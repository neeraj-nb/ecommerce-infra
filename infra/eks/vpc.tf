data "aws_availability_zones" "available" {}

resource "aws_vpc" "k8s-vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
  }
}

locals {
  all_subnets = [
    for i in range(4) : cidrsubnet(aws_vpc.k8s-vpc.cidr_block, 2, i)
  ]
  public_subnets = slice(local.all_subnets, 0, 2)
  private_subnets = slice(local.all_subnets, 2, 4)
}

resource "aws_subnet" "public_subnet" {
  count = 2
  vpc_id = aws_vpc.k8s-vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = local.public_subnets[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-k8s-public-${count.index}"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "owned"
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id = aws_vpc.k8s-vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = local.private_subnets[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-k8s-private-${count.index}"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "owned"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.k8s-vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
  }
}

resource "aws_eip" "nat_eip" {
  count = 2
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${count.index}"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id = aws_subnet.public_subnet[count.index].id
  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${count.index}"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
  }
  depends_on = [ aws_internet_gateway.internet_gateway ]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
  }
}

resource "aws_route_table" "private" {
  count = 2
  vpc_id = aws_vpc.k8s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = 2
  subnet_id = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}