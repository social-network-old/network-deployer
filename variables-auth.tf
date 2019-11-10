# AWS connection & authentication and Application configuration | variables-auth.tf

variable "aws_access_key" {
  type = string
  description = "AWS access key"
}

variable "aws_secret_key" {
  type = string
  description = "AWS secret key"
}

variable "aws_key_pair_name" {
  type = string
  description = "AWS key pair name"
}

variable "aws_key_pair_file" {
  type = string
  description = "Location of AWS key pair file"
}

variable "aws_region" {
  type = string
  description = "AWS region"
}

variable "app_name" {
  type = string
  description = "Application name"
}

variable "app_environment" {
  type = string
  description = "Application environment"
}

variable "admin_sources_cidr" {
  type        = list(string)
  description = "List of IPv4 CIDR blocks from which to allow admin access"
}

variable "app_sources_cidr" {
  type        = list(string)
  description = "List of IPv4 CIDR blocks from which to allow application access"
}
