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

# 1. Base VPC (DEV CIDR: 10.20.16.0/20)
resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.20.16.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "adarva-dev-vpc"
    Environment = "dev"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "adarva-dev-igw"
  }
}

# 3. ALB Public Subnets (/24)
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

# 4. EKS Worker Private Subnets (/23)
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
