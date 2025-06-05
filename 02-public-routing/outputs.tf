output "public_subnets" {
  value = aws_subnet.public
}

output "public_ip" {
  value = aws_instance.web.public_ip
}