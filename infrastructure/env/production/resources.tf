## WAF ALB
resource "aws_wafregional_web_acl_association" "web_acl_association_loadbalancer" {
  resource_arn = module.ecs.loadbalancer_id
  web_acl_id   = aws_wafregional_web_acl.web_acl_alb.id
}

resource "aws_wafregional_web_acl" "web_acl_alb" {
  name        = "${var.project_name}-${terraform.workspace}"
  metric_name = "${var.project_name}${terraform.workspace}"

  default_action {
    type = "ALLOW"
  }

  rule {
    priority = 1
    rule_id  = module.owasp_top_10.rule_group_id
    type     = "GROUP"

    override_action {
      type = "COUNT"
    }
  }
}