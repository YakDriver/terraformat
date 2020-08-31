// different types of heredocs

func testAccAWSCognitoUserPoolClientConfigAnalyticsConfigBase(userPoolName, clientName string) string {
	return fmt.Sprintf(`
data "aws_caller_identity" "current" {
}

resource "aws_cognito_user_pool" "test" {
  name = "%[1]s"
}

resource "aws_pinpoint_app" "test" {
  name = "%[2]s"
}

resource "aws_iam_role" "test" {
  name = "%[2]s"

assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Action": "sts:AssumeRole",
"Principal": {
"Service": "cognito-idp.amazonaws.com"
},
"Effect": "Allow",
"Sid": ""
}
]
}
EOF

}

resource "aws_iam_role_policy" "test" {
  name = "%[2]s"
  role = aws_iam_role.test.id

policy = <<-EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Action": [
"mobiletargeting:UpdateEndpoint",
"mobiletargeting:PutItems"
],
"Effect": "Allow",
"Resource": "arn:aws:mobiletargeting:*:${data.aws_caller_identity.current.account_id}:apps/${aws_pinpoint_app.test.application_id}*"
}
]
}
EOF

}
`, userPoolName, clientName)
}
