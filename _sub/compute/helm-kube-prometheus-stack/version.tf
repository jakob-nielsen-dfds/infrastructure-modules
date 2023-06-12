terraform {
  required_version = ">= 1.3.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.2.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.26.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.39.0"
    }
  }
}
