output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_security_group_id" {
  value = aws_security_group.eks_cluster_sg.id
}

output "mongodb_instance_public_ip" {
  value = aws_instance.mongodb_instance.public_ip
}

output "s3_backup_bucket_name" {
  value = aws_s3_bucket.backup_bucket.bucket
}
