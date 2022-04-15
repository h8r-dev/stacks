# Github repo operations

terraform {
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
