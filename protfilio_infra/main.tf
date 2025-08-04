terraform {

  backend "s3" {
    bucket       = "yuvalm-tf"
    key          = "tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }

  }
}

provider "aws" {
  region = "ap-south-1"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}


module "network" {
  source                = "./modules/network"
  name_prefix           = var.name_prefix
  vpc_cidr              = var.vpc_cidr_block
  subnets               = var.subnets
  tags                  = var.tags
  user_name             = var.user_name

}

module "compute" {
  source                = "./modules/compute"
  name_prefix           = var.name_prefix
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.public_subnet_ids

  tags                  = var.tags
  user_name             = var.user_name

}

module "argocd" {
  source                = "./modules/argocd"
  cluster_name          = module.compute.eks_cluster_name
  region                = "ap-south-1" 

}
