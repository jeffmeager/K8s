variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

