data "aws_availability_zones" "availability_zone" {}

data "terraform_remote_state" "network" {
    backend = "s3"
    config = {
      bucket = "neeraj-terraformstate"
      region = "ap-south-1"
      key = "network-ci/terraform.tfstate"
    }
}

resource "aws_security_group" "nexus_security_group" {
  name        = "nexus-sg"
  description = "Allow sexus services inbound traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "Allow Nexus UI access"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_instance" "nexus_instance" {
  ami = var.ami_id
  instance_type = var.instance_type
  availability_zone = data.aws_availability_zones.availability_zone[0]
  key_name = "lab"
  vpc_security_group_ids = [ aws_security_group.nexus_security_group.id ]
  subnet_id = data.terraform_remote_state.network.outputs.public_subnet_ids
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }
  tags = {
    Name = "Nexus Instance"
    managed = "terraform"
  }
}