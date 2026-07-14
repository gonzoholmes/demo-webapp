resource "aws_security_group" "mongodb" {
  name_prefix = "mongodb-"
  description = "Allow SSH and MongoDB access from within the VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH open to the internet (intentional lab misconfiguration)"
    from_port   = 22
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MongoDB from EKS private subnets only"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "tls_private_key" "mongodb" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "mongodb" {
  key_name   = "mongodb-key"
  public_key = tls_private_key.mongodb.public_key_openssh
}

resource "aws_secretsmanager_secret" "mongodb_ssh_private_key" {
  name                    = "wizlab/mongodb-ssh-private-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mongodb_ssh_private_key" {
  secret_id     = aws_secretsmanager_secret.mongodb_ssh_private_key.id
  secret_string = tls_private_key.mongodb.private_key_pem
}

resource "random_password" "mongodb_app" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "mongodb_app_password" {
  name                    = "wizlab/mongodb-app-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mongodb_app_password" {
  secret_id     = aws_secretsmanager_secret.mongodb_app_password.id
  secret_string = random_password.mongodb_app.result
}

resource "aws_instance" "mongodb" {
  # al2023-ami-2023.7.20250623.1-kernel-6.1-x86_64, (~1yr old)
  ami                         = "ami-05ffe3c48a9991133"
  instance_type               = var.mongodb_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.mongodb.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.mongodb.key_name
  iam_instance_profile        = aws_iam_instance_profile.mongodb_ec2.name
  user_data = templatefile("${path.module}/userdata-mongodb.sh", {
    bucket_name        = module.mongodb_bucket.s3_bucket_id
    mongo_app_user     = "starsigns_app"
    mongo_app_password = random_password.mongodb_app.result
  })

  tags = {
    Name        = "mongodb"
    Terraform   = "true"
    Environment = var.environment
  }
}
