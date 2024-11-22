resource "aws_ecr_repository" "application" {
  name                 = "peter-testing-org/example_container_app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

module "push_to_ecr_role_for_actions" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = true

  role_name = "push-to-ecr-role-for-actions"

  provider_url = var.github_actions_openid_connect_provider_url

  oidc_subjects_with_wildcards = ["repo:peter-testing-org/example_container_app:*"]

  role_policy_arns = [
    aws_iam_policy.ecr_push.arn,
  ]

  number_of_role_policy_arns = 1
}

module "iam_assumable_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  create_role = true

  role_name = "ecr-role-for-apprunner"
  role_requires_mfa = false

  tags = {
    Role = "ecr-role-for-apprunner"
  }

  custom_role_policy_arns = [
    aws_iam_policy.ecr_pull.arn,
  ]

  trusted_role_services = [
    "build.apprunner.amazonaws.com"
  ]
}

resource "aws_iam_policy" "ecr_push" {
  name        = "ecr_push"
  path        = "/"
  description = "ECR Push"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ],
        "Resource" : aws_ecr_repository.application.arn
      },
      {
        "Effect" : "Allow",
        "Action" : "ecr:GetAuthorizationToken",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_pull" {
  name        = "ecr_pull"
  path        = "/"
  description = "ECR Pull"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetDownloadUrlForLayer", 
          "ecr:BatchGetImage", 
          "ecr:DescribeImages", 
          "ecr:GetAuthorizationToken", 
          "ecr:BatchCheckLayerAvailability"
        ],
        "Resource" : aws_ecr_repository.application.arn
      },
      {
        "Effect" : "Allow",
        "Action" : "ecr:GetAuthorizationToken",
        "Resource" : "*"
      }
    ]
  })
}
