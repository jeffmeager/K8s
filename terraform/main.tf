terraform {
  backend "s3" {
    bucket         = "jeffmeager-challenge-terraform-state-bucket"
    key            = "challenge/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Challenge"
  }
}

# Subnets
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Challenge"
  }
}
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Challenge"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Challenge"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Challenge"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Challenge"
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

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain ="vpc"
  tags = {
    Name = "Challenge NAT EIP"
  }
}

# NAT Gateway in public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "Challenge NAT Gateway"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Challenge Private Route Table"
  }
}

# Route Table Association for private_az1
resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private.id
}

# Route Table Association for private_az2
resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private.id
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
    Name = "Challenge"
  }
}

resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb-sg"
  description = "Allow SSH and EKS to connect to MongoDB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH from anywhere (Challenge requirement)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow MongoDB from EKS Cluster SG"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Challenge MongoDB SG"
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
    Name = "Challenge"
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
    Name = "Challenge"
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
    Name = "Challenge"
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
    Name = "Challenge"
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

# EC2 Instance for MongoDB
resource "aws_instance" "mongodb_instance" {
  ami                         = "ami-055744c75048d8296" #Ubuntu 18.04 - Old as per challenge requirement, only in us-east-1
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.mongodb_sg.id]

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y gnupg wget curl

# Create challengeuser
useradd -m -s /bin/bash challengeuser

# Add challengeuser to the sudo group *without* requiring a password
usermod -aG sudo challengeuser
echo "challengeuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/challengeuser

mkdir -p /home/challengeuser/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiblVhQ+PQ9yB/M6KkhtMVNUP6/gYz65HuEB2psjyk55VnZUWZtPuiYeKTyT+ggK5XRWHBjgZERGn2yx1YB+BxOu6cUkPiJsUDlndHrHjafh2WfNcnauoDnLyHuvxFofSW+lsGoG9die9Tubc1mEqkTqlvZaUbKS9bTcpVBwbpVD5qoWRRceBfiflzFqJNkjIWzCRxLxf6qxeyhdYo0F3CdvsDZHEG/UR4FkFRUZ12u5cxE6rkUyIzkC44uNqo3ZUUoSgi3BuKFN1py2mEtGip4LKLy22bucNfuWITm+T5vWcdtmAGKXCC63G61y3C4VCxctWLGPlDG4hiWtqmPXeT user@host" > /home/challengeuser/.ssh/authorized_keys
chown -R challengeuser:challengeuser /home/challengeuser/.ssh
chmod 700 /home/challengeuser/.ssh
chmod 600 /home/challengeuser/.ssh/authorized_keys

# Lock ubuntu user
passwd -l ubuntu

# Install MongoDB 4.0 (Disabling GPG Check - UNSAFE!)
echo "deb [trusted=yes arch=amd64] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list

apt-get update
apt-get install -y mongodb-org=4.0.28 mongodb-org-server=4.0.28 mongodb-org-shell=4.0.28 mongodb-org-mongos=4.0.28 mongodb-org-tools=4.0.28

systemctl start mongod
systemctl enable mongod

# Wait for mongod to start
for i in {1..30}; do
  if nc -z localhost 27017; then
    echo "MongoDB is up!"
    break
  fi
  echo "Waiting for MongoDB to start ($i/30)..."
  sleep 1
done

mongo --eval "db.getSiblingDB('admin').createUser({user: '${var.mongodb_username}', pwd: '${var.mongodb_password}', roles:[{role:'root', db:'admin'}]})"
EOF



  tags = {
    Name    = "Challenge"
  }
}

resource "null_resource" "wait_for_cluster_ready" {
  depends_on = [null_resource.aws_auth_apply]

  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Sleeping 30 seconds to allow EKS API server DNS to propagate..."
      sleep 30
      echo "✅ Sleep complete. Proceeding."
    EOT
  }
}

# S3 Bucket for MongoDB Backups
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "challenge-docker-backups"
  tags = {
    Name = "Challenge"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.backup_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Public bucket policy
resource "aws_s3_bucket_policy" "backup_bucket_policy" {
  bucket = aws_s3_bucket.backup_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.backup_bucket.arn}/*"
      }
    ]
  })
  depends_on = [
    aws_s3_bucket_public_access_block.block_public_access
  ]
}