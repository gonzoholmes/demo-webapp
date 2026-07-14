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

output "mongodb_app_password_secret_arn" {
  value = aws_secretsmanager_secret.mongodb_app_password.arn
}

output "mongodb_ssh_private_key_secret_arn" {
  value = aws_secretsmanager_secret.mongodb_ssh_private_key.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "s3_bucket_name" {
  value = module.mongodb_bucket.s3_bucket_id
}

output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.main.arn
}


