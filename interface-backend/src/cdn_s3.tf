resource "aws_s3_bucket" "pokemons" {
  bucket = "jockey-webassets-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "pokemons" {
  bucket = aws_s3_bucket.pokemons.id

  policy = <<POLICY
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_cloudfront_origin_access_identity.s3_distribution.iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "${aws_s3_bucket.pokemons.arn}/*"
        }
    ]
}
POLICY
}

locals {
  s3_origin_id = "S3"
}

resource "aws_cloudfront_origin_access_identity" "s3_distribution" {
  comment = "Some comment"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.pokemons.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_distribution.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${aws_s3_bucket.pokemons.id}"
  default_root_object = "index.html"
  #aliases             = [""]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
