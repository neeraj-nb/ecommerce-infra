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

variable "ami_id" {
  description = "AMI ID to use for instance (default: custom AMI)"
  type = string
  default = "ami-089789c2d7416d122"
}

variable "instances_count" {
  description = "number of ec2 instances"
  type = number
  default = 1
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
  vpc_id      = aws_vpc.k8s_vpc.id

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

resource "aws_iam_role" "ec2_node_role" { # create IAM role
  name = "ec2-k8s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_node_profile" { # create instance profile with role to attach to instance
  name = "ec2-k8s-instance-profile"
  role = aws_iam_role.ec2_node_role.name
}

resource "aws_iam_policy" "alb_controller" { # create IAM policy for ALB controller
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "attach_alb_policy" { # attach policy to role
  role       = aws_iam_role.ec2_node_role.name
  policy_arn = aws_iam_policy.alb_controller.arn
}


resource "aws_instance" "k8s_node" {
  count = var.instances_count
  ami = var.ami_id
  instance_type = "t2.large"
  provider = aws.ap-south-1
  key_name = "lab"
  iam_instance_profile = aws_iam_instance_profile.ec2_node_profile.name # attach instacne profile with IAM role and profile
  vpc_security_group_ids = [aws_security_group.ssh.id]
  subnet_id = element(aws_subnet.public_subnet[*].id, count.index % length(aws_subnet.public_subnet)) # disctributing across subnets or AZ
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }
  tags = {
    Name = "K8s-node-${count.index + 1}"
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
  value = aws_instance.k8s_node[*].public_ip
}