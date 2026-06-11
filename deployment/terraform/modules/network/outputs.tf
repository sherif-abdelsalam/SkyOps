
output "private_subnet_ids" {
  value = [
    aws_subnet.private_zone1.id,
    aws_subnet.private_zone2.id,
    aws_subnet.private_zone3.id,
  ]
}