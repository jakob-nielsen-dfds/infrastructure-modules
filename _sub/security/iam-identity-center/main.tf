data "aws_ssoadmin_instances" "dfds" {}

resource "aws_ssoadmin_permission_set" "capabilityaccess" {
  name             = "CapabilityAccess"
  description      = "The default Capability permission set"
  instance_arn     = tolist(data.aws_ssoadmin_instances.dfds.arns)[0]
  session_duration = "PT8H"
}


data "aws_iam_policy_document" "capabilityaccess" {
  statement {
    sid = "Admin"

    effect = "Allow"

    actions = [
      "*"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "capabilityaccess" {
  inline_policy      = data.aws_iam_policy_document.capabilityaccess.json
  instance_arn       = aws_ssoadmin_permission_set.capabilityaccess.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.capabilityaccess.arn
}

resource "aws_ssoadmin_permission_set" "supportaccess" {
  name             = "SupportAccess"
  description      = "The permission set for handling support cases within capabilities"
  instance_arn     = tolist(data.aws_ssoadmin_instances.dfds.arns)[0]
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "supportaccess" {
  instance_arn       = aws_ssoadmin_permission_set.supportaccess.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.supportaccess.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSSupportAccess"
}
