variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "mongo_db_username" {
  type        = string
  description = "MongoDB admin username"
  default     = "wizuser"
}

variable "mongo_db_password" {
  type        = string
  description = "MongoDB admin password"
  sensitive   = true
}
