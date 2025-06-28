variable "instance_type" {
  default = "t2.large"
  type = string
}

variable "ami_id" {
  default = "ami-089789c2d7416d122"
  type = string
}

variable "region" {
  default = "ap-south-1"
  type = string
}

variable "cidr_block" {
  default = "10.0.0.0/16"
  type = string
}