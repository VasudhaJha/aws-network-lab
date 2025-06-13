output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [for subnet in aws_subnet.subnets : subnet.id]
}

output "subnet_cidrs" {
  value = [for subnet in aws_subnet.subnets : subnet.cidr_block]
}