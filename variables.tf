variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "interview"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "iam_username" {
  description = "Your IAM username suffix used in resource names"
  type        = string
}

# MUST be exactly the uploaded key name from Part 1
variable "key_name" {
  description = "Existing EC2 keypair name (created by Ansible)"
  type        = string
}

# Pick one of the allowed subnets from the list below
variable "subnet_id" {
  description = "One of the provided subnets in us-east-1"
  type        = string
  validation {
    condition = contains([
      "subnet-0d184093b3009cae6",
      "subnet-067818d7bdb30c97b",
      "subnet-05352ec468237a915",
      "subnet-0638273ad81d337ae",
      "subnet-0e6fca8b7cc1ed83e",
      "subnet-06b729959a9886c9d",
      "subnet-08e3f7bca5c38abe7"
    ], var.subnet_id)
    error_message = "subnet_id must be one of the allowed subnets from the exercise."
  }
}

# Fixed per the exercise
variable "instance_type" {
  type    = string
  default = "t2.nano"
}

variable "ami_id" {
  type    = string
  default = "ami-00a2faa3cbd561d33"
}

# Bucket details per the exercise (do not change)
variable "s3_bucket" {
  type    = string
  default = "cc-interviews-candidate-outputs"
}

