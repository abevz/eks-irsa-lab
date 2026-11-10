# infra/modules/state-backend/main.tf

#trivy:ignore:AVD-AWS-0089 
resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_145:SSE-S3 (AES256) is enough for a lab state bucket; a CMK adds cost and key-loss risk
  #checkov:skip=CKV_AWS_18:access logging needs a second bucket; out of scope for the lab
  #checkov:skip=CKV_AWS_144:cross-region replication is out of scope for the lab
  #checkov:skip=CKV2_AWS_62:event notifications are not needed for a state bucket
  bucket = var.bucket_name
  lifecycle { prevent_destroy = true }
}

data "aws_iam_policy_document" "state_tls_only" {
  statement {
    sid     = "EnforcedTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state_tls_only" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_tls_only.json

  depends_on = [aws_s3_bucket_public_access_block.pab_state]
}

resource "aws_s3_bucket_versioning" "versioning_state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "ssec_state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = 90
      newer_noncurrent_versions = 10
    }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.versioning_state]
}

resource "aws_s3_bucket_public_access_block" "pab_state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

