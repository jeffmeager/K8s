variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "profile" {
  description = "The AWS CLI profile to use"
  type        = string
  default     = "devops-admin"
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}