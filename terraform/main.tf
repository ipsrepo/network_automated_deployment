terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources to check if resources already exist
data "aws_key_pair" "existing" {
  key_name = "${var.project_name}-key"
}

data "aws_security_group" "existing" {
  name = "${var.project_name}-sg"
}

data "aws_iam_role" "existing" {
  name = "${var.project_name}-ec2-role"
}

data "aws_iam_instance_profile" "existing" {
  name = "${var.project_name}-instance-profile"
}

# Upload your public SSH key so EC2 can use it (only if it doesn't exist)
resource "aws_key_pair" "main" {
  count = try(data.aws_key_pair.existing.id, null) == null ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = var.public_key != "" ? var.public_key : file(var.public_key_path)
}

# Detect your current IP so only you can SSH in
data "http" "myip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_cidr = "${trimspace(data.http.myip.response_body)}/32"
}

# Security group: allow SSH from you, HTTP from everyone (only if it doesn't exist)
resource "aws_security_group" "web_sg" {
  count = try(data.aws_security_group.existing.id, null) == null ? 1 : 0
  name        = "${var.project_name}-sg"
  description = "Allow SSH and HTTP"

  ingress = [
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [local.my_cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [{
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# IAM role so the EC2 instance can use SSM (only if it doesn't exist)
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  count = try(data.aws_iam_role.existing.arn, null) == null ? 1 : 0
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  count      = try(data.aws_iam_role.existing.arn, null) == null ? 1 : 0
  role       = try(aws_iam_role.ec2_role[0].name, data.aws_iam_role.existing.name)
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count = try(data.aws_iam_instance_profile.existing.name, null) == null ? 1 : 0
  name = "${var.project_name}-instance-profile"
  role = try(aws_iam_role.ec2_role[0].name, data.aws_iam_role.existing.name)
}

# Get latest Amazon Linux 2023 AMI for ARM (Graviton / t4g.micro)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon official

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# Look up your existing Elastic IP by its public IP address
data "aws_eip" "existing_eip" {
  public_ip = var.elastic_ip_address
}

# Create EC2 instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  key_name                    = try(aws_key_pair.main[0].key_name, data.aws_key_pair.existing.key_name)
  vpc_security_group_ids      = [try(aws_security_group.web_sg[0].id, data.aws_security_group.existing.id)]
  iam_instance_profile        = try(aws_iam_instance_profile.ec2_profile[0].name, data.aws_iam_instance_profile.existing.name)
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-web"
  }
}

# Associate your existing Elastic IP with the EC2 instance
resource "aws_eip_association" "web_eip_assoc" {
  instance_id   = aws_instance.web.id
  allocation_id = data.aws_eip.existing_eip.id
}

# Outputs
output "public_ip" {
  description = "Temporary public IP (may change)"
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "Public DNS of the instance"
  value       = aws_instance.web.public_dns
}

output "elastic_ip" {
  description = "Your permanent Elastic IP address"
  value       = data.aws_eip.existing_eip.public_ip
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of your Elastic IP"
  value       = data.aws_eip.existing_eip.id
}

output "ssh_command" {
  description = "SSH command using Elastic IP (permanent)"
  value       = "ssh -i ~/.ssh/aws-key ec2-user@${data.aws_eip.existing_eip.public_ip}"
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "website_url" {
  description = "URL to access your website (permanent)"
  value       = "http://${data.aws_eip.existing_eip.public_ip}"
}