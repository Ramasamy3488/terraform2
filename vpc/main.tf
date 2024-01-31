terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.74.1"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}


resource "aws_vpc" "my-vpc" {
  cidr_block = "172.168.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name="MY-VPC"
  }
}
resource "aws_subnet" "mypublicsubnet" {
  vpc_id =  aws_vpc.my-vpc.id
  cidr_block = "172.168.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name="sub-pu"
  }
}
resource "aws_subnet" "myprivatesubnet" {
  vpc_id =  aws_vpc.my-vpc.id
  cidr_block = "172.168.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name="sub-pvt"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id =  aws_vpc.my-vpc.id
  tags = {
    Name="MY-IGW"
  }
}
resource "aws_route_table" "publRT" {
  vpc_id =  aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name="RT-PUB"
  }
}
resource "aws_route_table_association" "PubRTAss" {
  subnet_id = aws_subnet.mypublicsubnet.id
  route_table_id = aws_route_table.publRT.id
}
resource "aws_route_table" "privRT" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT-GW.id
    }
  tags = {
    Name="RT-PVT"
  }
}
resource "aws_route_table_association" "PriRTAss" {
  subnet_id = aws_subnet.myprivatesubnet.id
  route_table_id = aws_route_table.privRT.id
}
resource "aws_eip" "myEIP" {
  vpc   = true
}
resource "aws_nat_gateway" "NAT-GW" {
  allocation_id = aws_eip.myEIP.id
  subnet_id = aws_subnet.mypublicsubnet.id
  tags = {
    Name="NAT-GW"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  tags = {
    Name = "MY-VPC-SG"
  }
}
resource "aws_instance" "web-pub" {
  ami             = "ami-099b3d23e336c2e83"
  instance_type   = "t2.micro"
  subnet_id = aws_subnet.mypublicsubnet.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name        = "oct3"
  associate_public_ip_address = true

  tags = {
    Name = "web-pub"
    Env  = "Production"
  }
}
resource "aws_instance" "web-pvt" {
  ami             = "ami-099b3d23e336c2e83"
  instance_type   = "t2.micro"
  subnet_id = aws_subnet.myprivatesubnet.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name        = "oct3"

  tags = {
    Name = "web-pvt"
    Env  = "Production"
  }
}




