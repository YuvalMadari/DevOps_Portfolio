# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.name_prefix}-${var.user_name}-cluster-sg"
  description = "EKS control plane SG"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-SG"})

}

resource "aws_security_group_rule" "allow_http_cluster_api_access" {

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_sg.id
  depends_on = [ aws_security_group.eks_cluster_sg  ]
}
resource "aws_security_group_rule" "allow_port8080_cluster_api_access" {

  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_sg.id
  depends_on = [ aws_security_group.eks_cluster_sg  ]
}


resource "aws_security_group_rule" "allow_https_cluster_api_access" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_sg.id
  depends_on = [ aws_security_group.eks_cluster_sg  ]

}


resource "aws_security_group_rule" "allow_inside_traffic" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_sg.id
  depends_on = [
    aws_security_group.eks_cluster_sg
  ]
}

# EKS Cluster
resource "aws_eks_cluster" "cluster" {
  name     = "${var.name_prefix}-${var.user_name}-cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-CLUSTER"})
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]

}

# Node Group
resource "aws_eks_node_group" "ng" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.name_prefix}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 3
  }

  disk_size = 30

  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-NG"})

  labels = {
    Name = "${var.name_prefix}-${var.user_name}-node"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_policy.eks_passrole_policy
  ]

}

# Add this to your Terraform file
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.30.0-eksbuild.1"
  
  # This creates the service account with proper IRSA
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn
  
  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-ebs-csi"})
  
  depends_on = [
    aws_eks_node_group.ng
  ]
}

# IAM role for EBS CSI driver
resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "${var.user_name}-${var.name_prefix}-ebs-csi-driver-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name
}

# OIDC provider for EKS
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

#########################
# EKS Control Plane Role
#########################

resource "aws_iam_role" "cluster_role" {
  name = "${var.user_name}-${var.name_prefix}-cluster-role"
  
  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-cluster-role"})

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}


## For EKS Cluster Role
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role         = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy_attachment" "passrole_attachment" {
  policy_arn = aws_iam_policy.eks_passrole_policy.arn
  role       = aws_iam_role.eks_node_role.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_node_role.name
}


resource "aws_iam_policy" "eks_passrole_policy" {
  name        = "${var.user_name}-${var.name_prefix}-eks-passrole-policy"
  description = "Allows Terraform to pass IAM roles for EKS node groups"
  
  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-cluster-role"})

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["iam:PassRole"],
        Resource = aws_iam_role.eks_node_role.arn
      }
    ]
  })
}

#########################
# EKS Node Group Role
#########################

resource "aws_iam_role" "eks_node_role" {
  name = "${var.user_name}-${var.name_prefix}-eks-node-role"

  tags = merge(var.tags, {Name = "${var.name_prefix}-${var.user_name}-cluster-role"})

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}
## For EKS Node Role
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}
## For EKS Node Role
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}