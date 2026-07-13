module "mongodb_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "s3-bucket-gholmes8585-demowebapp-mongobackups"
  acl    = "public-read"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  # Lab environment only: opens the bucket to public read/list.
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "s3_public_read" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${module.mongodb_bucket.s3_bucket_arn}/*"]
  }

  statement {
    sid    = "PublicListBucket"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:ListBucket"]
    resources = [module.mongodb_bucket.s3_bucket_arn]
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = module.mongodb_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_public_read.json

  depends_on = [module.mongodb_bucket]
}


module "cloudtrail_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = "s3-bucket-gholmes8585-demowebapp-cloudtrail-logs"
  force_destroy = true
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [module.cloudtrail_bucket.s3_bucket_arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${module.cloudtrail_bucket.s3_bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = module.cloudtrail_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}