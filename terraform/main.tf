provider "aws" {
  region = "us-east-1"
}

# Updated http data source to use response_body instead of body
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

locals {
  current_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

# Dynamic AMI lookup for latest Amazon Linux 2
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# VPC with DNS support enabled
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "devops-vpc"
  }
}

# Internet Gateway for public subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "devops-igw"
  }
}

# Public subnet with route to IGW
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

# Route table for public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security group with temporary current IP access
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP from current IP"
  vpc_id      = aws_vpc.my_vpc.id

  # Temporary SSH access from your current IP only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.current_ip]
  }

  # HTTP access from anywhere
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
    Name = "devops-sg"
  }
}

# EC2 instance with simplified provisioning
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = "devops-key"
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  # Enhanced user data with logging
  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    
    echo "Starting installation..."
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ec2-user
    
    echo "Installation complete!"
    EOF

  tags = {
    Name = "web-server"
  }

  # Wait for SSH to be available (simpler than cloud-init status)
  provisioner "remote-exec" {
    inline = ["echo 'SSH connection established'"]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("../keys/devops-key.pem")
      host        = self.public_ip
    }
  }
}

# Outputs for easy access
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.allow_ssh_http.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.my_vpc.id
}
