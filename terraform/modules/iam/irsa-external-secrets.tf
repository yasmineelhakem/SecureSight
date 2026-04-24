# IAM role for external secrets operator to access AWS Secrets Manager

data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:sock-shop:external-secrets-sa"
      ]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name = "external-secrets-role-${var.environment}"
  
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json

  tags = merge(var.tags, {
    Name = "external-secrets-role-${var.environment}"
  })
}

resource "aws_iam_role_policy" "external_secrets_policy" {
  name = "external-secrets-secrets-manager-policy-${var.environment}"
  role = aws_iam_role.external_secrets.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/*"
    }]
  })
}