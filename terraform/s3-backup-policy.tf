data "aws_iam_policy_document" "mongodb_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mongodb_ec2" {
  name               = "mongodb-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.mongodb_assume_role.json
}

data "aws_iam_policy_document" "mongodb_s3_backup" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${module.mongodb_bucket.s3_bucket_arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [module.mongodb_bucket.s3_bucket_arn]
  }
}

resource "aws_iam_role_policy" "mongodb_s3_backup" {
  name   = "mongodb-s3-backup"
  role   = aws_iam_role.mongodb_ec2.id
  policy = data.aws_iam_policy_document.mongodb_s3_backup.json
}

resource "aws_iam_instance_profile" "mongodb_ec2" {
  name = "mongodb-ec2-profile"
  role = aws_iam_role.mongodb_ec2.name
}

data "aws_iam_policy_document" "mongodb_secrets_read" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.mongodb_app_password.arn]
  }
}

resource "aws_iam_role_policy" "mongodb_secrets_read" {
  name   = "mongodb-secrets-read"
  role   = aws_iam_role.mongodb_ec2.id
  policy = data.aws_iam_policy_document.mongodb_secrets_read.json
}

# Intentional: VM role is overpermissive
resource "aws_iam_role_policy_attachment" "mongodb_ec2_full_access" {
  role       = aws_iam_role.mongodb_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
