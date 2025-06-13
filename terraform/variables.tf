// Default "noop" added to assist with the teardown script complaining of missing values

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
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

# variable "admin_role_arn" {
#   type        = string
#   description = "Admin IAM Role ARNs for EKS access"
#   default     = "noop"
#   sensitive   = true
# }

variable "mongo_secret_key" {
  type    = string
}