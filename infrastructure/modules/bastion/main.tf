resource "aws_instance" "bastion" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  availability_zone           = "us-east-1a"
  iam_instance_profile        = aws_iam_instance_profile.bastion_instance_profile.id
  associate_public_ip_address = true
  subnet_id                   = var.public_subnet_1
  vpc_security_group_ids      = [aws_security_group.bastion.id]

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-bastion"
  }
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "${var.project_name}-${terraform.workspace}-bastion"
  role = aws_iam_role.bastion_role.id
}

resource "aws_iam_role" "bastion_role" {
  name = "${var.project_name}-${terraform.workspace}-bastion"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-BastionRole"
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${terraform.workspace}-bastion"
  description = "${var.project_name}-${terraform.workspace}-bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.remote_port
    to_port     = var.remote_port
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
    Name = "${var.project_name}-${terraform.workspace}-BastionSecurityGroup"
  }
}
