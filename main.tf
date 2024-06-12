provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-04b70fa74e45c3917" 
  instance_type = "t2.micro"
  
  tags = {
    Name = "example-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              EOF



  # Add a security group to allow inbound traffic on port 80 (HTTP)
  vpc_security_group_ids = [aws_security_group.instance.id]
}

resource "aws_security_group" "instance" {
  name        = "instance_security_group"
  description = "Allow inbound traffic on port 80"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output the public IP address of the instance
output "instance_ip" {
  value = aws_instance.example.public_ip
}
