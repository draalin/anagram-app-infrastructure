# Project
project_name = "slime"
domain_name  = "slime.wtf"

# Global
key_name   = "slime"
aws_region = "us-east-1"
az_count   = "2"

# ECS
instance_type   = "t3.micro"
asg_min         = "1"
asg_max         = "3"
asg_desired     = "1"
service_desired = "4"