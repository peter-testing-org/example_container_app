locals {
  region = "eu-west-1"
  name   = "ex-${basename(path.cwd)}"

  vpc_cidr = "10.0.0.0/16"
  # azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-app-runner"
    GithubOrg  = "terraform-aws-modules"
  }
}

module "app-runner" {
  source  = "terraform-aws-modules/app-runner/aws"
  version = "1.2.1"

  # Disable service resources
  create_service = false

  connections = {
    # The AWS Connector for GitHub connects to your GitHub account is a one-time setup,
    # You can reuse the connection for creating multiple App Runner services based on repositories in this account.
    # After creation, you must complete the authentication handshake using the App Runner console.
    github = {
      provider_type = "GITHUB"
    }
  }

  auto_scaling_configurations = {
    mini = {
      name            = "mini"
      max_concurrency = 20
      max_size        = 5
      min_size        = 1

      tags = {
        Type = "Mini"
      }
    }
  }

  tags = local.tags
}

module "app_runner_image_base" {
  source  = "terraform-aws-modules/app-runner/aws"
  version = "1.2.1"

  depends_on = [
    aws_ecr_repository.application
  ]

  service_name = "test-app-runner"

  enable_observability_configuration = false
  instance_iam_role_use_name_prefix = false
  access_iam_role_use_name_prefix = false

  # Pulling from shared configs
  auto_scaling_configuration_arn = module.app-runner.auto_scaling_configurations["mini"].arn

  # IAM instance profile permissions to access secrets
  # instance_policy_statements = {
  #   GetSecretValue = {
  #     actions   = ["secretsmanager:GetSecretValue"]
  #     resources = [aws_secretsmanager_secret.this.arn]
  #   }
  # }

  private_ecr_arn = aws_ecr_repository.application.arn
  source_configuration = {
    authentication_configuration = {
      access_role_arn = module.iam_assumable_role.iam_role_arn
    }
    auto_deployments_enabled = true
    image_repository = {
      image_configuration = {
        port = 80
        runtime_environment_variables = {
          MY_VARIABLE = "hello!"
        }
        # runtime_environment_secrets = {
        #   MY_SECRET = aws_secretsmanager_secret.this.arn
        # }
      }
      image_identifier      = "339712897199.dkr.ecr.eu-west-1.amazonaws.com/peter-testing-org/example_container_app:production_latest"
      image_repository_type = "ECR"
    }
  }
}