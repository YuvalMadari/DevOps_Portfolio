output "eks_cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "node_group_name" {
  value = aws_eks_node_group.ng.node_group_name
}
