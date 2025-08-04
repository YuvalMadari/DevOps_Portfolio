output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.compute.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.compute.eks_cluster_endpoint
}

output "node_group_name" {
  description = "The EKS node group name"
  value       = module.compute.node_group_name
}

output "vpc_id" {
  description = "The VPC ID used by the cluster"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.network.public_subnet_ids
}

# output "eks_cluster_role_arn" {
#   description = "IAM Role ARN for EKS control plane"
#   value       = module.iam.eks_cluster_role_arn
# }

# output "node_group_role_arn" {
#   description = "IAM Role ARN for EKS worker node group"
#   value       = module.iam.node_group_role_arn
# }
