data "aws_secretsmanager_secret_version" "gitlab_ssh" {
  secret_id = "yuvalm/sshforargocd"
}

locals {
  git_secret = jsondecode(data.aws_secretsmanager_secret_version.gitlab_ssh.secret_string)
}

resource "kubernetes_secret" "argocd_git_repo" {
  metadata {
    name      = "private-repo-secret-gitops"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
    annotations = {
      "managed-by" = "argocd.argoproj.io"
    }
  }

  data = {
    type                  = "git"
    url                   = "git@gitlab.com:yuvalmadari1/protfilio_gitops.git"
    sshPrivateKey         = local.git_secret.sshPrivateKey
    project               = "default"
    insecureIgnoreHostKey = "true"
  }

  type = "Opaque"
  depends_on = [null_resource.update_kubeconfig]
}



resource "null_resource" "update_kubeconfig" {
  # depends_on = [aws_eks_cluster.eks_cluster]
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
  }
}


# Helm chart release for ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace = "argocd" 
  version    = "8.0.14" 

  depends_on = [null_resource.update_kubeconfig]

}

# Create namespace for App
resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
  depends_on = [null_resource.update_kubeconfig]
}

# Create namespace for DB
resource "kubernetes_namespace" "database" {
  metadata {
    name = "database"
  }
  depends_on = [null_resource.update_kubeconfig]
}
