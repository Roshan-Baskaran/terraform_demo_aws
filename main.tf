provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
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
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"  # Change to your desired AZ

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"  # Change to your desired AZ

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.demo_vpc.id
  cidr_block        = "10.0.16.0/20"
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

resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.demo_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.demo_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "demokeypair"
  public_key = file("C:/Users/rbaskar/demokeypair.pub")  # Path to your public key
}

resource "aws_instance" "bastion_host" {
  ami                    = "ami-00beae93a2d981137"  
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_instance" "private_instance" {
  ami                    = "ami-00beae93a2d981137" 
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "private-instance"
  }
}

resource "aws_lb" "bastion_alb" {
  name               = "bastion-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "bastion-alb"
  }
}

resource "aws_lb_target_group" "bastion_tg" {
  name        = "bastion-tg"
  port        = 22
  protocol    = "TCP"
  vpc_id      = aws_vpc.demo_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    port                = "traffic-port"
    protocol            = "TCP"
  }

  tags = {
    Name = "bastion-tg"
  }
}

resource "aws_lb_listener" "bastion_listener" {
  load_balancer_arn = aws_lb.bastion_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bastion_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "bastion_attachment" {
  target_group_arn = aws_lb_target_group.bastion_tg.arn
  target_id        = aws_instance.bastion_host.id
  port             = 22
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

output "bastion_host_id" {
  description = "The ID of the bastion host EC2 instance"
  value       = aws_instance.bastion_host.id
}

output "private_instance_id" {
  description = "The ID of the private EC2 instance"
  value       = aws_instance.private_instance.id
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.bastion_alb.dns_name
}
