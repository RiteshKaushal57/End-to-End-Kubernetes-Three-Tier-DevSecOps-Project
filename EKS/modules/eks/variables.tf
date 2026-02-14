variable "cluster_name" {
  description = "Name of the cluster"
  type = string
}

variable "vpc_id" {
  description = "VPC id"
  type = string
}

variable "subnet_ids" {
  description = "List of subnet ids"
  type = list(string)
}

variable "node_instance_type" {
  description = "Type of node instance"
  type = string
}

variable "desired_size" {
    description = "Desired size of the node group"
    type = number
}

variable "max_size" {
    description = "Maximum size of the node group"
    type = number
}

variable "min_size" {
    description = "Minimum size of the node group"
    type = number
}