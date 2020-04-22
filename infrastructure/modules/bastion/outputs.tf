output bastion_public_dns {
  value = aws_instance.bastion.public_dns
}

output "bastion_security_group" {
  value = aws_security_group.bastion.id
}