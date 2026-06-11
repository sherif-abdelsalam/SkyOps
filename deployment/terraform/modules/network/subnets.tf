resource "aws_subnet" "private_zone1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/20"
  availability_zone = var.zone1

  tags = {
    "Name" = "${var.env}-private-${var.zone1}"

    # Marks this subnet for INTERNAL AWS Load Balancers
    # Used by EKS / AWS Load Balancer Controller
    # Internal ALBs/NLBs will be created here
    "kubernetes.io/role/internal-elb" = "1"

    # Tells EKS that this subnet belongs to this cluster
    # Required so EKS can discover and use the subnet
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

# Create the priavte subnet in zone 2
resource "aws_subnet" "private_zone2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.16.0/20"
  availability_zone = var.zone2

  tags = {
    "Name" = "${var.env}-private-${var.zone2}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

# Create the priavte subnet in zone 3
resource "aws_subnet" "private_zone3" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.32.0/20"
  availability_zone = var.zone3

  tags = {
    "Name" = "${var.env}-private-${var.zone3}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

###
# Public Subnets
###

# Create the public subnet in zone 1
resource "aws_subnet" "public_zone1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.48.0/20"
  availability_zone = var.zone1

  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.env}-public-${var.zone1}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

# Create the public subnet in zone 2
resource "aws_subnet" "public_zone2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.64.0/20"
  availability_zone = var.zone2

  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.env}-public-${var.zone2}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

# Create the public subnet in zone 3
resource "aws_subnet" "public_zone3" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.80.0/20"
  availability_zone = var.zone3

  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.env}-public-${var.zone3}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

