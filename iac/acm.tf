# El certificado ACM y su validación DNS se desactivan ya que no se utiliza un dominio personalizado para el entorno de desarrollo.
# resource "aws_acm_certificate" "frontend_cert" {
#   provider                  = aws.us_east_1
#   domain_name               = var.domain_name
#   subject_alternative_names = ["*.${var.domain_name}"]
#   validation_method         = "DNS"
# 
#   lifecycle {
#     create_before_destroy = true
#   }
# 
#   tags = {
#     Name        = "${var.project_name}-cert-${terraform.workspace}"
#     Environment = terraform.workspace
#     Project     = var.project_name
#     ManagedBy   = "Terraform"
#   }
# }
# 
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.frontend_cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
# 
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.zone_id
# }
# 
# resource "aws_acm_certificate_validation" "frontend_cert_validation" {
#   provider                = aws.us_east_1
#   certificate_arn         = aws_acm_certificate.frontend_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }