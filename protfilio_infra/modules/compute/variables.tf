variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS and node group"
  type        = list(string)
}

# variable "eks_cluster_role_arn" {
#   description = "IAM role ARN for EKS cluster"
#   type        = string
# }

# variable "node_group_role_arn" {
#   description = "IAM role ARN for EKS node group"
#   type        = string
# }

variable "user_name" {
  description = "user name for naming resources"
  type        = string
}

variable "tags" {

    description = "Tags nedded to create an object"
    type = map(string)
}


