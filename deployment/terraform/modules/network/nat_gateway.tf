resource "aws_eip" "nat" {

  # Allocate a static public IP inside the VPC
  # This IP will be attached to the NAT Gateway
  domain = "vpc"

  tags = {
    Name = "${var.env}-nat"
  }
}

resource "aws_nat_gateway" "nat" {

  # Attach the Elastic IP to the NAT Gateway
  # Gives the NAT Gateway a public internet IP
  allocation_id = aws_eip.nat.id

  # Place the NAT Gateway inside a PUBLIC subnet
  # NAT Gateway must be in a public subnet, so it can access the Internet Gateway
  subnet_id = aws_subnet.public_zone1.id

  tags = {
    Name = "${var.env}-nat"
  }

  # Ensure Internet Gateway is created first
  # NAT Gateway needs internet access through IGW
  depends_on = [aws_internet_gateway.igw]
}