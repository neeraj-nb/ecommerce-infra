output "instance_ip" {
  value = aws_instance.ci-server.public_ip
}