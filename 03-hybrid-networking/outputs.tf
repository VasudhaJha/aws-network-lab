output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_subnet_id" {
  description = "ID of the public subnet hosting NAT Gateway"
  value       = values(aws_subnet.public)[0].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.nat-gw.id
}

output "elastic_ip" {
  description = "Elastic IP address of the NAT Gateway"
  value       = aws_eip.eip.public_ip
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

# New outputs for instances
output "bastion_public_ip" {
  description = "Public IP address of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "Public DNS name of bastion host"
  value       = aws_instance.bastion.public_dns
}

output "private_instance_ip" {
  description = "Private IP addresses of instances in private subnets"
  value       = aws_instance.private.private_ip
}