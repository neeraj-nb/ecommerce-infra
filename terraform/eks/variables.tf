variable "kubernetes_version" {
  default = 1.32
  type = number
  description = "kubernetes version"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type = string
  description = "default CIDR range for VPC"
}

variable "aws_region" {
  default = "ap-south-1"
  type = string
  description = "aws region"
}

variable "cluster_name" {
  default = "ecom-cluster"
  type = string
  description = "name of the eks cluster"
}

variable "project_name" {
  default = "ecommerce"
  type = string
  description = "name of project"
}

variable "environment" {
  default = "dev"
  type = string
  description = "environment"
}