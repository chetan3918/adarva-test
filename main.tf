terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# 1. Base VPC for DEV/UAT (10.20.16.0/20)
resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.20.16.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "adarva-dev-vpc"
    Environment = "dev"
  }
}

# 2. Internet Gateway for Public Traffic
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "adarva-dev-igw"
  }
}

# 3. Public Subnets (ALB / Ingress: 10.20.17.0/24 & 10.20.18.0/24)
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.20.17.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                                    = "adarva-dev-alb-public-az1"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/adarva-eks-dev" = "shared"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.20.18.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                    = "adarva-dev-alb-public-az2"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/adarva-eks-dev" = "shared"
  }
}

# 4. Private Subnets for EKS Worker Nodes (10.20.19.0/23 & 10.20.21.0/23)
resource "aws_subnet" "private_worker_az1" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.20.19.0/23"
  availability_zone = "ap-south-1a"

  tags = {
    Name                                    = "adarva-dev-eks-worker-az1"
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/adarva-eks-dev" = "shared"
  }
}

resource "aws_subnet" "private_worker_az2" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.20.21.0/23"
  availability_zone = "ap-south-1b"

  tags = {
    Name                                    = "adarva-dev-eks-worker-az2"
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/adarva-eks-dev" = "shared"
  }
}

# 5. Route Table & Route to Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "adarva-dev-public-rt"
  }
}

resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}
