# Testing Pipeline A (plan-on-PR / apply-on-merge)
output "mongodb_private_ip" {
  value = aws_instance.mongodb.private_ip
}

output "mongodb_public_ip" {
  value = aws_instance.mongodb.public_ip
}

output "mongodb_app_password" {
  value     = random_password.mongodb_app.result
  sensitive = true
}

output "ecr_repository_url" {
  value = aws_ecr_repository.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "s3_bucket_name" {
  value = module.s3_bucket.s3_bucket_id
}
