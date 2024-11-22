terraform {
  source = "./app-runner-module"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "baseline" {
  config_path = "${get_parent_terragrunt_dir()}/_global/baseline"
  mock_outputs = {}
}

inputs = {
  github_actions_openid_connect_provider_arn = dependency.baseline.outputs.github_actions_iam_openid_connect_provider_arn
  github_actions_openid_connect_provider_url = dependency.baseline.outputs.github_actions_iam_openid_connect_provider_url
}
