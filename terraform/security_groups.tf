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
    cidr_blocks = ["10.0.0.0/16"]
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

resource "aws_security_group" "eks_node_sg" {
  vpc_id = aws_vpc.main.id
  name   = "eks-node-group-sg"

  ingress {
    description = "Allow all traffic from within Node Group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Challenge EKS Node Group SG"
  }
}

