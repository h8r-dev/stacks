resource "github_repository" "initRepo" {
  name        = var.repo_name
  description = "A repo created by Heighliner"

  # Private or public
  visibility = var.repo_visibility
}
