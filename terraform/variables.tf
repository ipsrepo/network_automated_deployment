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