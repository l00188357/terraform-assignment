variable "aws_region" {
  description = "AWS region for all resources. Must be an approved Irish/EU region."
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to connect via SSH (port 22)."
  type        = string
  default     = "10.0.0.0/16"
}