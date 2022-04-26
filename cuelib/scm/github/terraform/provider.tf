# Github repo operations
terraform {
  // init kubernetes backend
  backend "kubernetes" {
    namespace   = "default"
    config_path = "/kubeconfig"
  }
  // import dependent providers
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.23.0"
    }
  }
}

provider "github" {
  # Configuration options
}
