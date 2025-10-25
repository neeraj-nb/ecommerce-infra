terraform {
  backend "s3" {
    bucket = "neeraj-terraformstate"
    region = "ap-south-1"
    key = "jenkins/terraform.tfstate"
  }
}