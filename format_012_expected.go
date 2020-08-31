// hcl const vs json const vs hcl var vs json var

const testAccAWSIAMPolicyDocumentDataSourceConfigVersion20081017ConversionNotPrincipals = `
data "aws_iam_policy_document" "test" {
  version = "2008-10-17"

  statement {
    actions   = ["*"]
    resources = ["*"]

    not_principals {
      identifiers = ["&{aws:username}"]
      type        = "AWS"
    }
  }
}
`

const testAccAWSIAMPolicyDocumentDataSourceConfigVersion20081017ExpectedJSON = `{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    }
  ]
}`

var testAccAWSIAMPolicyDocumentDataSourceConfigVersion20081017ConversionNotPrincipals2 = callAFunction() + `
data "aws_iam_policy_document" "test" {
  version = "2008-10-17"

  statement {
    actions   = ["*"]
    resources = ["*"]

    not_principals {
      identifiers = ["&{aws:username}"]
      type        = "AWS"
    }
  }
}
`

var testAccAWSIAMPolicyDocumentDataSourceConfigVersion20081017ExpectedJSON2 = `{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    }
  ]
}`
