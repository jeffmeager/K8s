// Default "noop" added to assist with the teardown script complaining of missing values

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "mongodb_username" {
  type        = string
  description = "MongoDB admin username"
  default     = "noop"
  sensitive   = true
}

variable "mongodb_password" {
  type        = string
  description = "MongoDB admin password"
  default     = "noop"
  sensitive   = true
}

variable "build_id" {
  type        = string
  description = "Build identifier for unique secret naming"
  default     = "noop"
}

variable "admin_role_arn" {
  type        = string
  description = "Admin IAM Role ARNs for EKS access"
  default     = "noop"
  sensitive   = true
}
