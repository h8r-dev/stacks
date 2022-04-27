# Github repo operations
terraform {
  // import dependent providers
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.23.0"
    }
  }
  backend "kubernetes" {
    secret_suffix = var.secret_suffix
    namespace     = var.namespace
    config_path   = "/kubeconfig"
  }
}

provider "github" {
  # Configuration options
  owner = var.organization
  token = var.github_token
}
