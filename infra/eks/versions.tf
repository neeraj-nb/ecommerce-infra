terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "6.0.0"
    }

    helm = {
      source = "hashicorp/helm"
      version = "3.0.2"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.37.1"
    }
  }
}