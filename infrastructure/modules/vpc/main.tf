data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-VPC"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-InternetGateway"
  }
}

resource "aws_subnet" "public_subnet_1" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-PublicSubnet1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  availability_zone       = "us-east-1b"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-PublicSubnet2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.100.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-PrivateSubnet1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  availability_zone       = "us-east-1b"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.110.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-PrivateSubnet2"
  }
}

resource "aws_eip" "nat_gateway_eip_1" {
  vpc = true

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-NatGatewayEIP1"
  }
}
resource "aws_eip" "nat_gateway_eip_2" {
  vpc = true

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-NatGatewayEIP2"
  }
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-NatGateway1"
  }
}
resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_gateway_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-NatGateway2"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-DefaultPublicRoute"
  }
}

resource "aws_route_table_association" "public_subnet_1_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id

}

resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  }

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-DefaultPrivateRoute1"
  }
}

resource "aws_route_table_association" "private_subnet_1_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_2.id
  }

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-DefaultPrivateRoute2"
  }
}

resource "aws_route_table_association" "private_subnet_2_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}