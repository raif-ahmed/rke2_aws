locals {

  //  
  public_endpoints = var.publish_strategy == "External" ? true : false

  use_cname = contains(["us-gov-west-1", "us-gov-east-1"], var.region)
  use_alias = !local.use_cname

  public_zone = var.is_public_zone_exists ? data.aws_route53_zone.public[0] : aws_route53_zone.public[0]

}

data "aws_route53_zone" "public" {
  count = local.public_endpoints && var.is_public_zone_exists ? 1 : 0
  # count = 1
  name = var.base_domain
}

resource "aws_route53_zone" "public" {
  count         = local.public_endpoints && !var.is_public_zone_exists ? 1 : 0
  name          = var.cluster_domain
  force_destroy = true

  tags = merge(
    {
      "Name" = "${var.cluster_id}"
    },
    var.tags,
  )
}

resource "aws_route53_record" "api_external_alias" {
  count = local.use_alias && local.public_endpoints ? 1 : 0

  zone_id = local.public_zone.zone_id
  name    = "cp.${var.cluster_domain}"
  type    = "A"

  alias {
    name                   = var.api_external_lb_dns_name
    zone_id                = var.api_external_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_external_cname" {
  count = local.use_cname && local.public_endpoints ? 1 : 0

  zone_id = local.public_zone.zone_id
  name    = "cp.${var.cluster_domain}"
  type    = "CNAME"
  ttl     = 10

  records = [var.api_external_lb_dns_name]
}

resource "aws_route53_zone" "int" {
  name          = var.cluster_domain
  force_destroy = true

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(
    {
      "Name" = "${var.cluster_id}-int"
    },
    var.tags,
  )

  depends_on = [aws_route53_record.api_external_alias, aws_route53_record.api_external_cname]
}

resource "aws_route53_record" "api_internal_alias" {
  count = local.use_alias ? 1 : 0

  zone_id = aws_route53_zone.int.zone_id
  name    = "cp-int.${var.cluster_domain}"
  type    = "A"

  alias {
    name                   = var.api_internal_lb_dns_name
    zone_id                = var.api_internal_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_internal_cname" {
  count = local.use_cname ? 1 : 0

  zone_id = aws_route53_zone.int.zone_id
  name    = "cp-int.${var.cluster_domain}"
  type    = "CNAME"
  ttl     = 10

  records = [var.api_internal_lb_dns_name]
}


# resource "aws_route53_record" "api_external_internal_zone_alias" {
#   count = local.use_alias ? 1 : 0

#   zone_id = aws_route53_zone.int.zone_id
#   name    = "api.${var.cluster_domain}"
#   type    = "A"

#   alias {
#     name                   = var.api_internal_lb_dns_name
#     zone_id                = var.api_internal_lb_zone_id
#     evaluate_target_health = false
#   }
# }

# resource "aws_route53_record" "api_external_internal_zone_cname" {
#   count = local.use_cname ? 1 : 0

#   zone_id = aws_route53_zone.int.zone_id
#   name    = "api.${var.cluster_domain}"
#   type    = "CNAME"
#   ttl     = 10

#   records = [var.api_internal_lb_dns_name]
# }