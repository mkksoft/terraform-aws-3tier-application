terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-west-2"
  profile = "sbstage"
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_data.cidr_block
  tags = {
    "Name" = var.vpc_data.name
  }
}

# Create an Internet Gateway for each VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.vpc_data.name
  }
}

# Create public_subnets
resource "aws_subnet" "public_subnets" {
  for_each          = var.vpc_data.public_subnets
  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value.availability_zone
  cidr_block        = each.value.sub_cidr_block
  tags = {
    Name = each.value.sub_cidr_name
  }
}

# Create private_subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.vpc_data.private_subnets
  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value.availability_zone
  cidr_block        = each.value.sub_cidr_block
  tags = {
    Name = each.value.sub_cidr_name
  }
}

# Create db_subnets
resource "aws_subnet" "db_subnets" {
  for_each          = var.vpc_data.db_subnets
  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value.availability_zone
  cidr_block        = each.value.sub_cidr_block
  tags = {
    Name = each.value.sub_cidr_name
  }
}

# Create route table for public subnets
resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "SIT_PUB"
  }
}

# Create route table for private subnets
resource "aws_route_table" "pvt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "SIT_PVT"
  }
}

# Create route table association for pub
resource "aws_route_table_association" "pub" {
  for_each = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.pub.id
}

# Create route table association for private
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.pvt.id
}

# Create route table association for db
resource "aws_route_table_association" "db" {
  for_each = aws_subnet.db_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.pvt.id
}

resource "aws_db_subnet_group" "rds" {
  name       = "sit_rds_subnet_group"
  subnet_ids = [aws_subnet.db_subnets["db2a"].id,aws_subnet.db_subnets["db2b"].id,aws_subnet.db_subnets["db2c"].id]
  tags = {
    Name = "SIT_RDS_SUBNET_GROUP"
  }
}