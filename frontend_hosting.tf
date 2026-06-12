# Frontend estático — S3 privado + CloudFront (somente AWS real)

resource "aws_s3_bucket" "web" {
  count = local.create_frontend_hosting ? 1 : 0

  bucket = "${local.name_prefix}-web"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
  })
}

resource "aws_s3_bucket_public_access_block" "web" {
  count = local.create_frontend_hosting ? 1 : 0

  bucket = aws_s3_bucket.web[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "web" {
  count = local.create_frontend_hosting ? 1 : 0

  bucket = aws_s3_bucket.web[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "web" {
  count = local.create_frontend_hosting ? 1 : 0

  name                              = "${local.name_prefix}-web-oac"
  description                       = "OAC for ${local.name_prefix} static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "web" {
  count = local.create_frontend_hosting ? 1 : 0

  enabled             = true
  comment             = "${local.name_prefix} web"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  http_version        = "http2and3"

  origin {
    domain_name              = aws_s3_bucket.web[0].bucket_regional_domain_name
    origin_id                = "s3-web"
    origin_access_control_id = aws_cloudfront_origin_access_control.web[0].id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-web"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS Managed-CachingOptimized
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-cdn"
  })
}

data "aws_iam_policy_document" "web_bucket" {
  count = local.create_frontend_hosting ? 1 : 0

  statement {
    sid    = "AllowCloudFrontRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web[0].arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.web[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "web" {
  count = local.create_frontend_hosting ? 1 : 0

  bucket = aws_s3_bucket.web[0].id
  policy = data.aws_iam_policy_document.web_bucket[0].json
}
