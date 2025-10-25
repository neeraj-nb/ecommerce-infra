provider "aws" {
  region = var.region
}

data "aws_availability_zones" "availability_zone" {}

data "terraform_remote_state" "network" {
    backend = "s3"
    config = {
      bucket = "neeraj-terraformstate"
      region = "ap-south-1"
      key = "network-ci/terraform.tfstate"
    }
}

resource "aws_security_group" "ci-server-sg" {
  name        = "ci-sg"
  description = "Allow CI services inbound traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

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
  subnet_id = data.terraform_remote_state.network.outputs.public_subnet.id
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