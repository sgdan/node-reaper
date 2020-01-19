provider "aws" {
  region  = var.aws_region
  version = "~> 2.45"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "this" {
  name        = "node-reaper-role"
  description = "Allow the node-reaper pod to start/stop EC2 instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.provider_url}"
      }
      Condition = {
        StringEquals = {
          "${var.provider_url}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "this" {
  name = "node-reaper"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "ec2:Describe*",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:CreateTags"
      ],
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}
