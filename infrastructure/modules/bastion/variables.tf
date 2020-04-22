variable "project_name" {
  description = "Project Name"
  type        = string
  default     = null
}

variable "ami" {
  description = "Bastion AMI"
  type        = string
  default     = "ami-0b69ea66ff7391e80"
}

variable "key_name" {
  description = "PEM Key"
  type        = string
  default     = "devops"
}

variable "instance_type" {
  description = "Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "bastion_host_security_group" {
  description = "Bastion Host Securtiy Group"
  type        = string
  default     = null
}

variable "public_subnet_1" {
  description = "Public Subnet"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of VPC"
  type        = string
  default     = null
}

variable "remote_port" {
  description = "SSH or RDP port"
  type        = number
  default     = 22
}