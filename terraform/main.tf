terraform {
  backend "s3" {
    bucket         = "jeffmeager-challenge-terraform-state-bucket"
    key            = "wiz-challenge/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Wiz Challenge"
  }
}

# Subnets
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Wiz Challenge"
  }
}
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "Wiz Challenge"
  }
}


resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "Wiz Challenge"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Wiz Challenge"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Wiz Challenge"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Route Table Association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "eks_cluster_sg" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Wiz Challenge"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "challenge-eks-cluster"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = [aws_subnet.public.id, aws_subnet.private_az1.id, aws_subnet.private_az2.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
  tags = {
    Name = "Wiz Challenge"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.eks.name
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  tags = {
    Name = "Wiz Challenge"
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "Wiz Challenge"
  }
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "Wiz Challenge"
  }
}
# GOOD CONFIG #---------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

# ----------------------------------------------------------------------------------
# Overly permissive EKS Cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.eks.name
}

# Overly permissive EKS Node Group role
resource "aws_iam_role_policy_attachment" "eks_node_AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.eks_node.name
}
# -----------------------------------------------------------------------------------

# Collect link to really old Linux distro
data "aws_ami" "ubuntu_1604" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance for MongoDB
resource "aws_instance" "mongodb_instance" {
  ami           = aws.ami.ubuntu_1604.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y gnupg wget curl

              wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | apt-key add -
              echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list

              apt-get update
              apt-get install -y mongodb-org=4.0.28 mongodb-org-server=4.0.28 mongodb-org-shell=4.0.28 mongodb-org-mongos=4.0.28 mongodb-org-tools=4.0.28

              systemctl start mongod
              systemctl enable mongod

              mongo --eval "db.getSiblingDB('admin').createUser({user: '${var.mongodb_username}', pwd: '${var.mongodb_password}', roles:[{role:'root', db:'admin'}]})"
              EOF

  tags = {
    Name    = "Wiz Challenge"
  }
}

# S3 Bucket for MongoDB Backups
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "challenge-docker-backups"
  tags = {
    Name = "Wiz Challenge"
  }
}
