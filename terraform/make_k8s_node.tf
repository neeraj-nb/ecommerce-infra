provider "aws" {
  region = "ap-south-1"
  alias = "ap-south-1"
}

data "aws_availability_zones" "available" {}

variable "cluster_name" {
  description = "Ecommerce project cluster"
  type        = string
  default     = "ecom-cluster"
}

resource "aws_vpc" "k8s_vpc" {   # create vpc for isolation and tagging resources for alb
  cidr_block = "10.0.0.0/16" # first 16 bit constant
  enable_dns_support = true  # allow dns resolution
  enable_dns_hostnames = true # public DNS hotname
  tags = {
    Name = "k8s-vpc"
  }
}

resource "aws_internet_gateway" "igw" { # allow internet access to public subnet in VPC
  vpc_id = aws_vpc.k8s_vpc.id
}

resource "aws_subnet" "public_subnet" { # public subnet
  count             = 2                 # 2 subnet for HA
  cidr_block        = cidrsubnet(aws_vpc.k8s_vpc.cidr_block, 8, count.index)
  vpc_id            = aws_vpc.k8s_vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true        # map Public IP for ec2 instances

  tags = {
    Name = "k8s-public-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # required by ALB, owned - resource for a single cluster
    "kubernetes.io/role/elb"                    = "1"     # mark subnet for internet facing ALB
  }
}

resource "aws_route_table" "public_rt" { # traffic routing map
  vpc_id = aws_vpc.k8s_vpc.id
}

resource "aws_route" "public_internet_access" { # create route to igw
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0" # anywhere
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" { # add route table to subnet
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_node_1" {
  ami = "ami-0f918f7e67a3323f0"
  instance_type = "t2.large"
  provider = aws.ap-south-1
  key_name = "lab"
  vpc_security_group_ids = [aws_security_group.ssh.id]
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }
  tags = {
    Name = "K8s-node-1"
    Terraform = "true"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # required by ALB
  }
}

output "vpc_id" {
  value = aws_vpc.k8s_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "public_ip_1" {
  value = aws_instance.k8s_node_1.public_ip
}