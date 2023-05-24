provider "aws" {
  region = var.aws_region

  # Assume role in Master account
  assume_role {
    role_arn = "arn:aws:iam::${var.master_account_id}:role/${var.prime_role_name}"
  }
}

provider "aws" {
  region = var.aws_region
  alias  = "core"
}

provider "aws" {
  region = var.aws_region

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn = module.org_account.org_role_arn
  }

  alias = "workload"
}

provider "aws" {
  region = var.aws_region_sso
  alias  = "sso"

  # Assume role in Master account
  assume_role {
    role_arn = "arn:aws:iam::${var.master_account_id}:role/${var.prime_role_name}"
  }
}


provider "datadog" {
  api_key  = var.datadog_api_key
  app_key  = var.datadog_app_key
  api_url  = var.datadog_api_url
  validate = var.datadog_enabled
}

terraform {
  backend "s3" {
  }
}

module "iam_policies" {
  source                            = "../../_sub/security/iam-policies"
  iam_role_trusted_account_root_arn = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
}

module "org_account" {
  source        = "../../_sub/security/org-account"
  name          = var.name
  org_role_name = var.org_role_name
  email         = var.email
  parent_id     = var.parent_id
}

module "iam_account_alias" {
  source        = "../../_sub/security/iam-account-alias"
  account_alias = module.org_account.name

  providers = {
    aws = aws.workload
  }
}

module "cloudtrail_s3_local" {
  source           = "../../_sub/storage/s3-cloudtrail-bucket"
  create_s3_bucket = var.cloudtrail_local_s3_bucket != "" ? true : false
  s3_bucket        = var.cloudtrail_local_s3_bucket

  providers = {
    aws = aws.workload
  }
}

module "cloudtrail_local" {
  source     = "../../_sub/security/cloudtrail-config"
  deploy     = var.cloudtrail_local_s3_bucket != "" ? true : false
  s3_bucket  = module.cloudtrail_s3_local.bucket_name
  trail_name = "local-audit"

  providers = {
    aws = aws.workload
  }
}

module "iam_identity_center_assignment" {
  source = "../../_sub/security/iam-identity-center-assignment"

  permission_set_name = var.sso_admin_permission_set_name
  group_name          = var.sso_admin_group_name
  aws_account_id      = module.org_account.id

  providers = {
    aws = aws.sso
  }
}

resource "aws_iam_role" "prime" {
  name                 = var.prime_role_name
  description          = "Admin role to be assumed by Prime"
  assume_role_policy   = module.iam_policies.trusted_account
  max_session_duration = var.prime_role_max_session_duration
  provider             = aws.workload
}

# Create the a Prime Admin role in the Workload account
resource "aws_iam_role_policy" "prime-admin" {
  name     = "Admin"
  role     = aws_iam_role.prime.id
  policy   = module.iam_policies.admin
  provider = aws.workload
}

module "iam_role_certero" {
  source               = "../../_sub/security/iam-role"
  role_name            = "CerteroRole"
  role_description     = ""
  max_session_duration = 3600
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy_master_account.json
  role_policy_name     = "CerteroEndpoint"
  role_policy_document = module.iam_policies.certero_endpoint

  providers = {
    aws = aws.workload
  }
}

module "datadog" {
  deploy                           = var.datadog_enabled
  source                           = "../../_sub/monitoring/datadog-integration-aws"
  aws_account_id                   = module.org_account.id
  datadog_aws_account_id           = var.datadog_aws_account_id
  filter_tags                      = var.datadog_filter_tags
  host_tags                        = var.datadog_host_tags
  account_specific_namespace_rules = var.datadog_account_specific_namespace_rules
  metrics_collection_enabled       = var.datadog_metrics_collection_enabled
  resource_collection_enabled      = var.datadog_resource_collection_enabled

  providers = {
    aws = aws.workload
  }
}
