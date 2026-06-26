terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Red Virtual (VPC)
resource "aws_vpc" "valetsgo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "valetsgo-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "valetsgo_igw" {
  vpc_id = aws_vpc.valetsgo_vpc.id
  tags   = { Name = "valetsgo-igw" }
}

# Subred pública
resource "aws_subnet" "valetsgo_subnet" {
  vpc_id                  = aws_vpc.valetsgo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags                    = { Name = "valetsgo-subnet" }
}

# Tabla de rutas
resource "aws_route_table" "valetsgo_rt" {
  vpc_id = aws_vpc.valetsgo_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.valetsgo_igw.id
  }
  tags = { Name = "valetsgo-rt" }
}

resource "aws_route_table_association" "valetsgo_rta" {
  subnet_id      = aws_subnet.valetsgo_subnet.id
  route_table_id = aws_route_table.valetsgo_rt.id
}

# Security Group (puertos 22, 80, 443, 3001)
resource "aws_security_group" "valetsgo_sg" {
  name   = "valetsgo-sg"
  vpc_id = aws_vpc.valetsgo_vpc.id

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
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "valetsgo-sg" }
}

# Llave SSH
resource "aws_key_pair" "valetsgo_key" {
  key_name   = "valetsgo-key"
  public_key = file(var.ssh_public_key_path)
}

# Instancia EC2 t2.micro (Free Tier)
resource "aws_instance" "valetsgo_vm" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.valetsgo_subnet.id
  vpc_security_group_ids = [aws_security_group.valetsgo_sg.id]
  key_name               = aws_key_pair.valetsgo_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
  EOF

  tags = { Name = "valetsgo-server" }
}
