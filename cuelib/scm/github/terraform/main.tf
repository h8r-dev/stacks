# Github repo operations
terraform {
  backend "kubernetes" {
    /* secret_suffix = will be set on command line with -backend-config */
    namespace = "default"
    config_path = "/kubeconfig"
  }
  required_providers {
    github = {
      source = "integrations/github"
      version = "4.23.0"
    }
  }
}

provider "github" {
  # Configuration options
}