provider "aws" {
  region = "ap-south-1"
  alias = "ap-south-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

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
  tags = {
    Name = "K8s-node_1"
    Terraform = "true"
  }
}

output "public_ip_1" {
  value = aws_instance.k8s_node_1.public_ip
}