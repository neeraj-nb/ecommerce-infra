provider "aws" {
  region = var.region
}

data "aws_availability_zones" "availability_zone" {}

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

resource "aws_security_group" "ci-server-sg" {
  name        = "ci-sg"
  description = "Allow CI services inbound traffic"
  vpc_id      = aws_vpc.ci-server-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ci-server" {
  ami = var.ami_id
  instance_type = var.instance_type
  availability_zone = data.aws_availability_zones.availability_zone.names[0]
  key_name = "lab"
  vpc_security_group_ids = [ aws_security_group.ci-server-sg.id ]
  subnet_id = aws_subnet.public_subnet.id
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }
  tags = {
    Name = "CI-server"
    managed = "terraform"
  }
}