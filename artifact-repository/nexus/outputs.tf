output "instance_ip" {
  value = aws_instance.nexus_instance.public_ip
}