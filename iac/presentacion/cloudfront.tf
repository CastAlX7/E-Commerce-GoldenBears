locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "golden-bears-frontend-oac"
  description                       = "OAC para el frontend de Golden Bears"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Política de cabeceras de respuesta
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "golden-bears-security-headers-policy"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true  
      preload                    = true
      override                   = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    content_type_options {
      override = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
  }
}

resource "aws_cloudfront_distribution" "frontend_cdn" {
  # Origin Failover Configurado
  origin_group {
    origin_id = "s3_origin_group"
    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }
    member {
      origin_id = local.s3_origin_id
    }
    member {
      origin_id = "failoverS3Origin"
    }
  }

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
    origin_id                = local.s3_origin_id
  }

  # Origen secundario para el Failover
  origin {
    domain_name              = "${var.bucket_name}-replica.s3.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
    origin_id                = "failoverS3Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  
  web_acl_id = aws_wafv2_web_acl.frontend_waf.arn

  # Access Logging del CDN habilitado
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.frontend.bucket_regional_domain_name
    prefix          = "cloudfront/"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3_origin_group"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    min_ttl                    = 0
    default_ttl                = 3600
    max_ttl                    = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}