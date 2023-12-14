aws_workload_account_id = "266901158286" # 266901158286 = QA
workload_dns_zone_name  = "qa.dfds.cloud"

aws_assume_role_arn = "arn:aws:iam::266901158286:role/QA"

terraform_state_s3_bucket = "dfds-qa-terraform-state"
terraform_state_region    = "eu-central-1"

eks_public_s3_bucket = "dfds-qa-k8s-public"

eks_is_sandbox = true

tags = {
  "dfds.owner"                         = "dfds-qa" # owner set to dummy value on purpose
  "dfds.env"                           = "test"
  "dfds.cost.centre"                   = "ti-arch"
  "dfds.service.availability"          = "low"
  "dfds.automation.tool"               = "Terraform"
  "dfds.automation.initiator.location" = "https://github.com/dfds/infrastructure-modules"
}

data_tags = {
  "dfds.data.backup"         = false
  "dfds.data.classification" = "private"
}
