module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
}

module "bastion" {
  source          = "../../modules/bastion"
  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  public_subnet_1 = module.vpc.public_subnet_1
  key_name        = var.key_name
}

module "acm" {
  source       = "../../modules/acm"
  project_name = var.project_name
  domain_name  = var.domain_name
}

module "route53" {
  source             = "../../modules/route53"
  project_name       = var.project_name
  domain_name        = var.domain_name
  aws_alb            = module.ecs.aws_alb
  bastion_public_dns = module.bastion.bastion_public_dns
}

module "ecs" {
  source                 = "../../modules/ecs"
  project_name           = var.project_name
  aws_region             = var.aws_region
  domain_name            = var.domain_name
  min_size               = var.asg_min
  max_size               = var.asg_max
  desired_capacity       = var.asg_desired
  asg_min                = var.asg_min
  asg_max                = var.asg_max
  asg_desired            = var.asg_desired
  desired_count          = var.service_desired
  service_desired        = var.service_desired
  instance_type          = var.instance_type
  key_name               = var.key_name
  certificate            = module.acm.certificate
  private_subnet_1       = module.vpc.private_subnet_1
  private_subnet_2       = module.vpc.private_subnet_2
  public_subnet_1        = module.vpc.public_subnet_1
  public_subnet_2        = module.vpc.public_subnet_2
  vpc_id                 = module.vpc.vpc_id
  bastion_security_group = module.bastion.bastion_security_group
}

module "owasp_top_10" {
  source                         = "../../modules/waf"
  project_name                   = var.project_name
  product_domain                 = "tsi"
  service_name                   = "slime"
  environment                    = "production"
  description                    = "OWASP Top 10 rules"
  target_scope                   = "regional"
  create_rule_group              = "true"
  max_expected_uri_size          = "512"
  max_expected_query_string_size = "4096"
  max_expected_body_size         = "4096"
  max_expected_cookie_size       = "4093"
  csrf_expected_header           = "x-csrf-token"
  csrf_expected_size             = "36"
}