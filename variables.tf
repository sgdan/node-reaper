variable "aws_region" {
  description = "Region where node reaper will be deployed"
}

variable "provider_url" {
  description = "URL of OIDC provider for EKS cluster"
}

variable "namespace" {
  description = "The k8s namespace to deploy the node-reaper pod to"
}

variable "service_account" {
  description = "Name of service account which will be linked to IAM role"
}
