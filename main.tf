terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.region
}

# Base name exactly as required: interview-terraform-<IAM_USERNAME>
locals {
  resource_name = "interview-terraform-${var.iam_username}"
}

# Lookup VPC from the chosen subnet (must be one of the allowed IDs in variables.tf)
data "aws_subnet" "selected" {
  id = var.subnet_id
}

# Security Group named exactly as required; open ports 22 and 80
resource "aws_security_group" "web_sg" {
  name        = local.resource_name
  description = "Allow SSH (22) and HTTP (80)"
  vpc_id      = data.aws_subnet.selected.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.resource_name
  }
}

# ---------- IAM for EC2 to upload to the specific S3 prefix ----------

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${local.resource_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
  tags               = { Name = local.resource_name }
}

# Allow PUT only to s3://cc-interviews-candidate-outputs/terraform/interview-terraform-<USER>/*
data "aws_iam_policy_document" "s3_put" {
  statement {
    sid       = "AllowPutObjectToSpecificPrefix"
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["arn:aws:s3:::${var.s3_bucket}/terraform/${local.resource_name}/*"]
  }

  statement {
    sid       = "AllowListBucketForPrefix"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_bucket}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["terraform/${local.resource_name}/*"]
    }
  }
}

resource "aws_iam_policy" "s3_put_policy" {
  name   = "${local.resource_name}-s3-put"
  policy = data.aws_iam_policy_document.s3_put.json
  tags   = { Name = local.resource_name }
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_put_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.resource_name}-profile"
  role = aws_iam_role.ec2_role.name
  tags = { Name = local.resource_name }
}

# ---------- Render user-data with built-in templatefile() ----------
# NOTE: IPV4 and URL are passed as dummies to avoid errors if your template still references them.
locals {
  user_data_rendered = templatefile("${path.module}/user_data.sh.tpl", {
    region    = var.region
    s3_bucket = var.s3_bucket
    s3_prefix = "terraform/${local.resource_name}/index.html"
    index_b64 = base64encode(file("${path.module}/index.html"))
    IPV4      = "" # not used if your template fetches IP via IMDS
    URL       = "" # not used if your template computes URL locally
  })
}

# ---------- EC2 instance ----------
resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = local.user_data_rendered

  tags = {
    Name = local.resource_name
  }
}

