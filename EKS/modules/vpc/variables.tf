variable "project_name" {
  description = "Project name"
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type = list(string)
}