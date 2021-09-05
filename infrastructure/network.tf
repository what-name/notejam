variable "vpc_cidr" { type = string }
variable "subnet_nat_gateway_a" { type = string }
variable "subnet_nat_gateway_b" { type = string }
variable "subnet_rds_a" { type = string }
variable "subnet_rds_b" { type = string }
variable "subnet_ecs_cidr_a" { type = string }
variable "subnet_ecs_cidr_b" { type = string }
variable "subnet_lb_cidr_a" { type = string }
variable "subnet_lb_cidr_b" { type = string }


# VPC
# ===================================================

resource "aws_vpc" "notejam" {
  cidr_block            = var.vpc_cidr
  instance_tenancy      = "default"
  enable_dns_hostnames  = true

  tags = {
      Name = "${var.project}-${terraform.workspace}"
  }
}

# Internet gateway
# ===================================================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.notejam.id
  tags = {
      Name = "${var.project}-${terraform.workspace}-igw"
  }
}

# NAT Gateways
# ===================================================

# Elastic IPs
resource "aws_eip" "eip_a" {
  vpc = true
}

resource "aws_eip" "eip_b" {
  vpc = true
}

# to be used in RTB for private subnets where internet access is needed
resource "aws_nat_gateway" "nat_gateway_a" {
  subnet_id     = aws_subnet.nat_gateway_a.id
  allocation_id = aws_eip.eip_a.id
}

resource "aws_nat_gateway" "nat_gateway_b" {
  subnet_id     = aws_subnet.nat_gateway_b.id
  allocation_id = aws_eip.eip_b.id
}

# SUBNETS
# ===================================================

# RDS
resource "aws_subnet" "rds_a" {
  availability_zone = "${var.region}a"
  cidr_block        = var.subnet_rds_a
  vpc_id            = aws_vpc.notejam.id
  tags = {
    Name = "${var.project}-${terraform.workspace}-rds-a"
  }
}

resource "aws_subnet" "rds_b" {
  availability_zone = "${var.region}b"
  cidr_block        = var.subnet_rds_b
  vpc_id            = aws_vpc.notejam.id

  tags = {
    Name = "${var.project}-${terraform.workspace}-rds-b"
  }
}

# ECS
resource "aws_subnet" "ecs_a" {
  availability_zone = "${var.region}a"
  cidr_block        = var.subnet_ecs_cidr_a
  vpc_id            = aws_vpc.notejam.id
  tags = {
      Name = "${var.project}-${terraform.workspace}-ecs-a"
  }
}
resource "aws_subnet" "ecs_b" {
  availability_zone = "${var.region}b"
  cidr_block        = var.subnet_ecs_cidr_b
  vpc_id            = aws_vpc.notejam.id

  tags = {
      Name = "${var.project}-${terraform.workspace}-ecs-b"
  }
}

# LB
resource "aws_subnet" "lb_a" {
  availability_zone = "${var.region}a"
  cidr_block        = var.subnet_lb_cidr_a
  vpc_id            = aws_vpc.notejam.id

  tags = {
      Name = "${var.project}-${terraform.workspace}-lb-a"
  }
}
resource "aws_subnet" "lb_b" {
  availability_zone = "${var.region}b"
  cidr_block        = var.subnet_lb_cidr_b
  vpc_id            = aws_vpc.notejam.id

  tags = {
      Name = "${var.project}-${terraform.workspace}-lb-b"
  }
}

# Nat gateway
resource "aws_subnet" "nat_gateway_a" {
  availability_zone = "${var.region}a"
  cidr_block        = var.subnet_nat_gateway_a
  vpc_id            = aws_vpc.notejam.id

  tags = {
    Name = "${var.project}-${terraform.workspace}-nat-gateway-a"
  }
}

resource "aws_subnet" "nat_gateway_b" {
  availability_zone = "${var.region}b"
  cidr_block        = var.subnet_nat_gateway_b
  vpc_id            = aws_vpc.notejam.id

  tags = {
      Name = "${var.project}-${terraform.workspace}-nat-gateway-b"
  }
}

# ROUTE TABLES
# ===================================================

# PRIVATE ROUTE TABLE
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.notejam.id

  # default route via nat_gateway
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_a.id
  }
  tags = {
    Name = "${var.project}-${terraform.workspace}-private"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.notejam.id

  # default route via nat_gateway
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_b.id
  }
  tags = {
    Name = "${var.project}-${terraform.workspace}-private"
  }
}

# PUBLIC ROUTE TABLE
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.notejam.id

  # default route via igw
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
      Name = "${var.project}-${terraform.workspace}-public"
  }
}


# Subnet <-> Route table associations
# ===================================================

# Load Balancer
resource "aws_route_table_association" "lb_a" {
  subnet_id = aws_subnet.lb_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "lb_b" {
  subnet_id = aws_subnet.lb_b.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway
resource "aws_route_table_association" "nat_gateway_a" {
  subnet_id = aws_subnet.nat_gateway_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "nat_gateway_b" {
  subnet_id = aws_subnet.nat_gateway_b.id
  route_table_id = aws_route_table.public.id
}

# ECS
resource "aws_route_table_association" "ecs_a" {
  subnet_id = aws_subnet.ecs_a.id
  route_table_id = aws_route_table.private_a.id
}
resource "aws_route_table_association" "ecs_b" {
  subnet_id = aws_subnet.ecs_b.id
  route_table_id = aws_route_table.private_b.id
}

