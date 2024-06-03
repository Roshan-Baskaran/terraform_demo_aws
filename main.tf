# main.tf

provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_internet_gateway" "public_gw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "public-gw"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_gw.id
  }

  tags = {
    Name = "public-route"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "private-route"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.demo_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"  # Change to your desired AZ

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"  # Change to your desired AZ

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.demo_vpc.id
  cidr_block = "10.0.16.0/20"
  availability_zone = "us-east-1a"  # Change to your desired AZ

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.demo_vpc.id
}

output "public_subnet_id_1" {
  description = "The ID of the first public subnet"
  value       = aws_subnet.public_subnet_1.id
}

output "public_subnet_id_2" {
  description = "The ID of the second public subnet"
  value       = aws_subnet.public_subnet_2.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private_subnet.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.public_gw.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public_route.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private_route.id
}
