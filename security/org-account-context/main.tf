# --------------------------------------------------
# Init
# --------------------------------------------------

provider "aws" {
  region = var.aws_region

  # Assume role in Master account
  assume_role {
    role_arn     = "arn:aws:iam::${var.master_account_id}:role/${var.prime_role_name}"
    session_name = var.aws_session_name
  }
}

provider "aws" {
  region = var.aws_region
  alias  = "core" # this provider does not seem to be used?
}

provider "aws" {
  region = var.aws_region
  alias  = "shared"

  # Assume role in Shared account
  assume_role {
    role_arn     = "arn:aws:iam::${var.shared_account_id}:role/${var.prime_role_name}"
    session_name = var.aws_session_name
  }
}

provider "aws" {
  region = var.aws_region
  alias  = "workload"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}

provider "aws" {
  region = var.aws_region_2
  alias  = "workload_2"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}

provider "aws" {
  region = var.aws_region_sso
  alias  = "sso"

  # Assume role in Master account
  assume_role {
    role_arn     = "arn:aws:iam::${var.master_account_id}:role/${var.prime_role_name}"
    session_name = var.aws_session_name
  }
}

####################################################################################################################
# Following providers are needed to deploy Resource Explorer in all available regions
####################################################################################################################
# EU
provider "aws" {
  region = "eu-west-1"
  alias  = "workload_eu-west-1"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}
provider "aws" {
  region = "eu-west-2"
  alias  = "workload_eu-west-2"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}
provider "aws" {
  region = "eu-west-3"
  alias  = "workload_eu-west-3"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}

# USA
provider "aws" {
  region = "us-east-1"
  alias  = "workload_us-east-1"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}
provider "aws" {
  region = "us-east-2"
  alias  = "workload_us-east-2"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}
provider "aws" {
  region = "us-west-1"
  alias  = "workload_us-west-1"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}
provider "aws" {
  region = "us-west-2"
  alias  = "workload_us-west-2"

  # Need explicit credentials in Master, to be able to assume Organizational Role in Workload account
  access_key = var.access_key_master
  secret_key = var.secret_key_master

  # Assume the Organizational role in Workload account
  assume_role {
    role_arn     = module.org_account.org_role_arn
    session_name = var.aws_session_name
  }
}

####################################################################################################################


terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

module "iam_policies" {
  source                            = "../../_sub/security/iam-policies"
  iam_role_trusted_account_root_arn = ["arn:aws:iam::${var.core_account_id}:root"] # Account ID from variable instead of data.aws_caller_identity - seems to get rate-throttled
}

module "iam_policies_shared" {
  source        = "../../_sub/security/iam-policies"
  replace_token = var.capability_root_id
}


# --------------------------------------------------
# Create account
# --------------------------------------------------

module "org_account" {
  source        = "../../_sub/security/org-account"
  name          = var.name
  org_role_name = var.org_role_name
  email         = var.email
  parent_id     = var.parent_id
  sleep_after   = 120
}

module "iam_account_alias" {
  source        = "../../_sub/security/iam-account-alias"
  account_alias = module.org_account.name

  providers = {
    aws = aws.workload
  }
}

# --------------------------------------------------
# IAM roles - Shared
# --------------------------------------------------

module "iam_role_shared" {
  source               = "../../_sub/security/iam-role"
  role_name            = var.capability_root_id
  role_path            = var.shared_role_path
  role_description     = "Namespaced access to resources in shared account, e.g. Parameter Store, CloudWatch Logs etc."
  max_session_duration = 28800 # 8 hours
  assume_role_policy   = data.aws_iam_policy_document.shared_role_cap_acc.json
  role_policy_name     = "NamespacedAccessInSharedAccount"
  role_policy_document = module.iam_policies_shared.capability_access_shared

  providers = {
    aws = aws.shared
  }
}

# --------------------------------------------------
# IAM roles - Workload (capability context)
# --------------------------------------------------

module "iam_role_sso_reader" {
  source               = "../../_sub/security/iam-role"
  role_name            = "sso-reader"
  role_description     = "Reads autogenerated roles created for SSO access"
  max_session_duration = 28800 # 8 hours
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy_selfservice.json
  role_policy_name     = "IamRead"
  role_policy_document = module.iam_policies.ssoreader

  providers = {
    aws = aws.workload
  }
}

module "iam_role_ecr_push" {
  source               = "../../_sub/security/iam-role"
  role_name            = "ecr-push"
  role_description     = ""
  max_session_duration = 3600
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy_self.json
  role_policy_name     = "PushToECR"
  role_policy_document = module.iam_policies.push_to_ecr

  providers = {
    aws = aws.workload
  }
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

# --------------------------------------------------
# IAM deployment user
# --------------------------------------------------

resource "aws_iam_group" "admin" {
  name     = "Admins"
  provider = aws.workload
}

resource "aws_iam_group_policy" "admin" {
  name     = "Admin"
  group    = aws_iam_group.admin.name
  policy   = module.iam_policies.admin
  provider = aws.workload
}

module "iam_user_deploy" {
  source            = "../../_sub/security/iam-user"
  user_name         = "Deploy"
  group_memberships = [aws_iam_group.admin.name]

  providers = {
    aws = aws.workload
  }
}

# --------------------------------------------------
# IAM OpenID Connect Provider
# --------------------------------------------------

module "aws_iam_oidc_provider" {
  source                          = "../../_sub/security/iam-oidc-provider"
  eks_openid_connect_provider_url = var.oidc_provider_url
  eks_cluster_name                = var.oidc_provider_tag

  providers = {
    aws = aws.workload
  }
}

# --------------------------------------------------
# aws_context_account_created event
# --------------------------------------------------

locals {
  # account_created_payload = <<EOF
  # {"contextId":"${var.context_id}","accountId":"${module.org_account.id}","roleArn":"${module.iam_role_capability.arn}","roleEmail":"${module.org_account.email}","capabilityRootId":"${var.capability_root_id}","capabilityName":"${var.capability_name}","contextName":"${var.context_name}","capabilityId":"${var.capability_id}"}EOF
  account_created_payload_map = {
    "contextId"        = var.context_id
    "accountId"        = module.org_account.id
    "roleEmail"        = module.org_account.email
    "capabilityRootId" = var.capability_root_id
    "capabilityName"   = var.capability_name
    "contextName"      = var.context_name
    "capabilityId"     = var.capability_id
  }

  account_created_payload_json = jsonencode(local.account_created_payload_map)
}

module "kafka_produce_account_created" {
  source          = "../../_sub/misc/kafka-message"
  publish         = var.publish_message
  event_name      = "aws_context_account_created"
  message_version = "1"
  correlation_id  = var.correlation_id
  sender          = "org-account-context created by terraform"
  payload         = local.account_created_payload_json
  key             = var.capability_id
  broker          = var.kafka_broker
  topic           = "build.selfservice.events.capabilities"
  username        = var.kafka_username
  password        = var.kafka_password
}

# --------------------------------------------------
# AWS Resource Explorer Feature
# --------------------------------------------------

module "aws_resource_explorer-metrics" {
  source = "../../_sub/monitoring/aws-resource-explorer-metrics"

  allowed_assume_arn = "arn:aws:iam::${var.master_account_id}:role/aws-resource-exporter"

  providers = {
    aws = aws.workload
  }
}

resource "aws_resourceexplorer2_index" "aggregator" {
  type = "AGGREGATOR"

  provider = aws.workload
}

resource "aws_resourceexplorer2_view" "aggregator_view" {
  name         = "all-resources"
  default_view = true

  included_property {
    name = "tags"
  }

  depends_on = [aws_resourceexplorer2_index.aggregator]
  provider   = aws.workload
}


resource "aws_resourceexplorer2_index" "us-east-1" {
  type = "LOCAL"

  provider = aws.workload_us-east-1
}

resource "aws_resourceexplorer2_index" "us-east-2" {
  type = "LOCAL"

  provider = aws.workload_us-east-2
}
resource "aws_resourceexplorer2_index" "us-west-1" {
  type = "LOCAL"

  provider = aws.workload_us-west-1
}

resource "aws_resourceexplorer2_index" "us-west-2" {
  type = "LOCAL"

  provider = aws.workload_us-west-2
}


resource "aws_resourceexplorer2_index" "eu-west-1" {
  type = "LOCAL"

  provider = aws.workload_eu-west-1
}

# --------------------------------------------------
# Account hardening
# --------------------------------------------------
module "hardened-account" {
  count = var.harden ? 1 : 0
  providers = {
    aws.workload   = aws.workload
    aws.workload_2 = aws.workload_2
    aws.sso        = aws.sso
  }
  source = "../../_sub/security/hardened-account"

  harden                          = var.harden
  account_id                      = module.org_account.id
  account_name                    = var.name
  security_bot_lambda_version     = var.security_bot_lambda_version
  security_bot_lambda_s3_bucket   = var.security_bot_lambda_s3_bucket
  monitoring_email                = var.hardened_monitoring_email
  monitoring_slack_channel        = var.hardened_monitoring_slack_channel
  monitoring_slack_token          = var.hardened_monitoring_slack_token
  security_contact_name           = var.hardened_security_contact_name
  security_contact_title          = var.hardened_security_contact_title
  security_contact_email          = var.hardened_security_contact_email
  security_contact_phone_number   = var.hardened_security_contact_phone_number
  sso_support_permission_set_name = var.sso_support_permission_set_name
  sso_support_group_name          = var.sso_support_group_name
}

# --------------------------------------------------
# Github OIDC provider
# --------------------------------------------------

module "github_oidc_provider" {
  count = length(var.repositories) > 0 && length(var.oidc_role_access) > 0 ? 1 : 0
  providers = {
    aws = aws.workload
  }
  source = "../../_sub/security/iam-github-oidc-provider"

  repositories     = var.repositories
  oidc_role_access = var.oidc_role_access
}
