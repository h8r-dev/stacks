# Operate repositories

variable "repo_name" {
  type = string
}

variable "repo_visibility" {
  type    = string
  default = "private"
}

variable "github_token" {
  type = string
}

variable "organization" {
  type = string
}
