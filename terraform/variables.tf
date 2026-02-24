variable "project_name" {
  default = "devops-app"
}

variable "aws_region" {
  default = "eu-west-1" # Ireland region
}

variable "instance_type" {
  default = "t4g.micro" # free tier
}

variable "public_key_path" {
  default = "~/.ssh/aws-key.pub"
}

variable "public_key" {
  description = "The public key content for EC2 instance (used in CI/CD)"
  type        = string
  default     = ""
}

variable "elastic_ip_address" {
  default = "52.48.24.168"
}