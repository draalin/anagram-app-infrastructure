# Elastic Container Service
# ECR Repo

resource "aws_ecr_repository" "web" {
  name                 = "${var.project_name}-web"
  image_tag_mutability = "MUTABLE"
}

# ECS
data "template_file" "instance_profile" {
  template = "${file("../../modules/ecs/files/instance-profile-policy.json")}"

  vars = {
    web_log_group_arn = aws_cloudwatch_log_group.web.arn
    ecs_log_group_arn = aws_cloudwatch_log_group.ecs.arn
  }
}

data "template_file" "cloud_config" {
  template = "${file("../../modules/ecs/files/cloud-config.yml")}"

  vars = {
    aws_region         = var.aws_region
    ecs_cluster_name   = aws_ecs_cluster.main.name
    ecs_log_level      = "info"
    ecs_agent_version  = "latest"
    ecs_log_group_name = aws_cloudwatch_log_group.ecs.name
  }
}

data "template_file" "user_data" {
  template = file("../../modules/ecs/files/user-data.sh")

  vars = {
    ecs_cluster_name = aws_ecs_cluster.main.name
  }
}

data "aws_ami" "stable_coreos" {
  most_recent = true

  filter {
    name   = "description"
    values = ["CoreOS Container Linux stable *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}

data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_iam_role" "ecsInstanceRole" {
  name = "ecsInstanceRole"
}

## EC2 - Auto Scaling
resource "aws_launch_configuration" "app" {
  security_groups = [
    aws_security_group.frontend.id,
  ]

  name_prefix = "${var.project_name}-ECS-"
  image_id    = data.aws_ami.stable_coreos.id
  # image_id             = data.aws_ami.amazon_linux_ecs.id
  instance_type        = var.instance_type
  iam_instance_profile = data.aws_iam_role.ecsInstanceRole.id
  # iam_instance_profile        = aws_iam_instance_profile.app.name
  user_data = data.template_file.cloud_config.rendered
  # user_data                   = data.template_file.user_data.rendered
  associate_public_ip_address = false
  key_name                    = "slime"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [image_id]
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix          = "${var.project_name}-asg"
  vpc_zone_identifier  = [var.private_subnet_1, var.private_subnet_2]
  min_size             = var.asg_min
  max_size             = var.asg_max
  desired_capacity     = var.asg_desired
  launch_configuration = aws_launch_configuration.app.name

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.project_name}-ecs"
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_policy" "up" {
  name                   = "${var.project_name}-policy-up"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  scaling_adjustment     = 1
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "down" {
  name                   = "${var.project_name}-policy-down"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  scaling_adjustment     = -1
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_ec2" {
  alarm_name          = "${var.project_name}-ec2_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.web.name
  }

  alarm_actions = [aws_autoscaling_policy.up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_ec2" {
  alarm_name          = "${var.project_name}-ec2_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.web.name
  }

  alarm_actions = [aws_autoscaling_policy.down.arn]
}

## ECS - Auto Scaling - Web
resource "aws_appautoscaling_target" "target_web" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 2
}

resource "aws_appautoscaling_policy" "up_web" {
  name               = "${var.project_name}-web-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "down_web" {
  name               = "${var.project_name}-web-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_high_web" {
  alarm_name          = "${var.project_name}-web_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "85"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.web.name
  }

  alarm_actions = [aws_appautoscaling_policy.up_web.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_low_web" {
  alarm_name          = "${var.project_name}-web_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "20"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.web.name
  }

  alarm_actions = [aws_appautoscaling_policy.down_web.arn]
}

## ECS
resource "aws_ecs_cluster" "main" {
  name = var.project_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

### Task Definitions

data "template_file" "task_definition_web" {
  template = "${file("../../modules/ecs/files/task-definition_web.json")}"

  vars = {
    image_url_web      = aws_ecr_repository.web.repository_url
    container_name_web = "${var.project_name}-web"
    log_group_region   = var.aws_region
    log_group_name     = aws_cloudwatch_log_group.web.name
  }
}

resource "aws_ecs_task_definition" "web" {
  family                = "${var.project_name}-web"
  container_definitions = data.template_file.task_definition_web.rendered
}

### Services
resource "aws_ecs_service" "web" {
  name            = "${var.project_name}-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = var.service_desired
  iam_role        = aws_iam_role.ecs_service.name

  load_balancer {
    target_group_arn = aws_alb_target_group.web.id
    container_name   = "${var.project_name}-web"
    container_port   = "3000"
  }

  depends_on = [
    aws_iam_role_policy.ecs_service,
    aws_alb_listener.front_end
  ]

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

## IAM
resource "aws_iam_role" "ecs_service" {
  name = "${var.project_name}_ecs_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "tf_example_ecs_policy"
  role = aws_iam_role.ecs_service.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-ecs-instprofile"
  role = aws_iam_role.app_instance.name
}

resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAccess" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role" "app_instance" {
  name = "${var.project_name}-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "instance" {
  name   = "TfEcsExampleInstanceRole"
  role   = aws_iam_role.app_instance.name
  policy = data.template_file.instance_profile.rendered
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "ecs" {
  name = "${var.project_name}-ecs-group/ecs-agent"
}

resource "aws_cloudwatch_log_group" "web" {
  name = "${var.project_name}-ecs-group/web"
}

# Application Load Balancer
resource "aws_alb_target_group" "web" {
  name     = "${var.project_name}-ecs-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    matcher = "200,401"
  }
}


resource "aws_alb" "main" {
  name            = "${var.project_name}-alb-ecs"
  subnets         = [var.public_subnet_1, var.public_subnet_2]
  security_groups = [aws_security_group.loadbalancer.id]

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-alb"
  }
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate

  default_action {
    target_group_arn = aws_alb_target_group.web.id
    type             = "forward"
  }
}

# WWW

resource "aws_lb_listener" "forward_https" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "host_based_routing_www" {
  listener_arn = aws_alb_listener.front_end.arn
  priority     = 100

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = var.domain_name
    }
  }

  condition {
    field  = "host-header"
    values = ["www.${var.domain_name}"]
  }
}

# Security Groups
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-${terraform.workspace}-frontend"
  description = "${var.project_name}-${terraform.workspace}-frontend"
  vpc_id      = var.vpc_id


  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.bastion_security_group]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.loadbalancer.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-FrontendSecurityGroup"
  }
}

resource "aws_security_group" "loadbalancer" {
  name        = "${var.project_name}-${terraform.workspace}-loadbalancer"
  description = "${var.project_name}-${terraform.workspace}-loadbalancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-LoadBalancerSecurityGroup"
  }
}
