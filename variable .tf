variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be created"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs in different AZs"
}
