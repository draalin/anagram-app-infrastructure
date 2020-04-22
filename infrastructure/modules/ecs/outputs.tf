output "aws_alb" {
  value = aws_alb.main.dns_name
}

output "frontend_security_group" {
  value = aws_security_group.frontend.id
}
output "loadbalancer_security_group" {
  value = aws_security_group.loadbalancer.id
}

output "loadbalancer_id" {
  value = aws_alb.main.id
}