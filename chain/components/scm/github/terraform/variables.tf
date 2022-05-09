# Operate repositories

variable "repo_name" {
  type = string
}

variable "repo_visibility" {
  type    = string
  default = "private"
}

variable "namespace" {
  type = string
}

variable "secret_suffix" {
  type = string
}
